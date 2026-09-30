import '../models/contact.dart';
import '../models/location_info.dart';
import 'congress_service.dart';
import 'location_service.dart';
import 'state_service.dart';
import '../data/county_data.dart';

LocationInfo? _cachedLocation;
double? _cachedLat;
double? _cachedLng;
Future<LocationInfo> getCachedLocation(double lat, double lng) async {
  if (_cachedLocation != null && _cachedLat == lat && _cachedLng == lng) {
    return _cachedLocation!;
  }

  final location = await resolveLocation(lat, lng);
  _cachedLocation = location;
  _cachedLat = lat;
  _cachedLng = lng;
  return location;
}

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
      final all = countyDictionary[location.county] ?? [];
      if (issueId == null) return all;
      // A contact with no issueIds is a general/countywide office (County
      // Executive, County Council, 311) and shows for every county issue.
      // One with issueIds only shows when it actually matches — this is what
      // stops something like "report a pothole" from also surfacing the
      // Sheriff, State's Attorney, and Health Department.
      return all.where((c) => c.issueIds.isEmpty || c.issueIds.contains(issueId)).toList();

    default:
      return [];
  }
}