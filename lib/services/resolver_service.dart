/// Central router from "issue level" to a list of officials.
///
/// `getContactsForIssue` maps a level (`federal_house`, `federal_senate`,
/// `state`, `county`) to the right source: Congress.gov, Open States or the
/// local county directory. `getCachedLocation` avoids repeating the Census
/// lookup. The Results screen is the main caller.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../models/location_info.dart';
import 'congress_number.dart';
import 'congress_service.dart';
import 'location_service.dart';
import 'state_service.dart';
import '../data/county_data.dart';

/// The most recently resolved location, kept in memory for this app session.
LocationInfo? _memoryLocation;
/// The [_locationKey] that [_memoryLocation] was resolved for.
String? _memoryKey;

/// Forgets the location kept in memory. Tests call this between cases so one
/// test's location (e.g. Baltimore County) doesn't leak into the next.
@visibleForTesting
void resetLocationCache() {
  _memoryLocation = null;
  _memoryKey = null;
}

/// Rounds coordinates to 3 decimals (~100 m) so tiny GPS jitter reuses the
/// same cached answer.
String _locationKey(double lat, double lng) =>
    '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

/// Resolves a position to a county/state/district, reusing the answer from
/// memory or from disk (so it survives app restarts and works offline).
/// The stored answer is discarded when the position moves more than ~100 m
/// or a new Congress begins (district lines can change).
Future<LocationInfo> getCachedLocation(double lat, double lng) async {
  final key = _locationKey(lat, lng);
  if (_memoryLocation != null && _memoryKey == key) return _memoryLocation!;

  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('resolved_location');
  if (stored != null) {
    try {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      if (map['key'] == key && map['congress'] == currentCongress()) {
        final location = LocationInfo.fromJson(map['location'] as Map<String, dynamic>);
        _memoryLocation = location;
        _memoryKey = key;
        return location;
      }
    } catch (e) {
      debugPrint('Ignoring unreadable saved location: $e');
    }
  }

  final location = await resolveLocation(lat, lng);
  _memoryLocation = location;
  _memoryKey = key;
  await prefs.setString(
    'resolved_location',
    jsonEncode({'key': key, 'congress': currentCongress(), 'location': location.toJson()}),
  );
  return location;
}

/// Key used by the county directory, e.g. "Baltimore County, MD".
String countyKeyFor(LocationInfo location) => '${location.county}, ${location.stateAbbr}';

/// Human-readable list of the counties that have a hand-checked directory,
/// e.g. "Baltimore County, MD" or "Baltimore County, MD and Howard County, MD".
/// Read from the directory itself, so adding a county updates every notice.
String coveredCountiesText() {
  final names = countyDictionary.entries
      .where((e) => e.value.isNotEmpty)
      .map((e) => e.key)
      .toList()
    ..sort();
  if (names.isEmpty) return 'no counties yet';
  if (names.length == 1) return names.first;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// True when the app has hand-checked county offices for this location.
bool hasCountyDirectory(LocationInfo location) =>
    (countyDictionary[countyKeyFor(location)] ?? const []).isNotEmpty;

/// Returns the officials for one government [level] at [location]. For the
/// county level, [issueId] narrows the list to offices relevant to that issue;
/// an unknown level gives an empty list.
Future<List<Contact>> getContactsForIssue(String level, LocationInfo location, {String? issueId}) async {
  switch (level) {
    case 'federal_house':
      // A House rep lookup is meaningless without a district — this is the
      // one level that actually needs it. Fail soft (empty list, which the
      // Results screen already shows a clear "no contacts found" state for)
      // instead of calling the Congress API with a null/garbage value.
      if (location.congressionalDistrict == null) return [];
      return await fetchFederalReps(location.stateAbbr, location.congressionalDistrict!);

    case 'federal_senate':
      return await fetchSenators(location.stateAbbr);

    case 'state':
      return await fetchStateLegislators(location.lat, location.lng);

    case 'county':
      final all = countyDictionary[countyKeyFor(location)] ?? [];
      if (issueId == null) return all;
      // A contact with no issueIds is a general/countywide office (County
      // Executive, County Council, 311) and shows for every county issue.
      // One with issueIds only shows when it actually matches — this is what
      // stops something like "report a pothole" from also surfacing the
      // Sheriff, State's Attorney, and Health Department.
      //
      // Offices built for this exact issue come first (BGE for street lights,
      // Animal Services for strays), then the general offices, so the first
      // card is always the best place to start.
      final specific = all.where((c) => c.issueIds.contains(issueId));
      final general = all.where((c) => c.issueIds.isEmpty);
      return [...specific, ...general];

    default:
      return [];
  }
}