/// Turns coordinates (or a street address) into county, state and district.
///
/// Calls the free U.S. Census geocoder. `resolveLocation` fetches and
/// `parseCensusResponse` (pure, unit tested) reads the answer. `searchAddresses`
/// (suggestions) and `geocodeAddress` (best match) power the address picker for
/// people who don't share GPS.
/// `resolver_service.dart` caches the result; the Home/Hub screens show it as
/// a label. If the Census data has no district, `congressionalDistrict` is null
/// so only House-rep lookups are skipped and county/state lookups still work.
library;

import 'package:flutter/foundation.dart';

import '../models/location_info.dart';
import 'api_client.dart';

const _notInUs = "These coordinates don't appear to be inside the United States.";

Future<LocationInfo> resolveLocation(double lat, double lng) async {
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw AppException('Those coordinates are out of range.');
  }
  final url = Uri.parse(
    'https://geocoding.geo.census.gov/geocoder/geographies/coordinates'
    '?x=$lng&y=$lat&benchmark=Public_AR_Current&vintage=Current_Current&format=json',
  );
  final data = await getJson(url, service: 'The Census geocoder');
  return parseCensusResponse(data, lat, lng);
}

/// Reads a Census "geographies" response. The congressional-district layer
/// and its field are named after the Congress number ("119th Congressional
/// Districts" / "CD119"), so they are found by pattern and need no yearly edit.
LocationInfo parseCensusResponse(dynamic data, double lat, double lng) {
  final result = data is Map ? data["result"] : null;
  final geographies = result is Map ? result["geographies"] : null;
  if (geographies is! Map) throw AppException(_notInUs);

  final states = geographies['States'] as List?;
  if (states == null || states.isEmpty) throw AppException(_notInUs);
  final stateData = states[0];

  final counties = geographies['Counties'] as List?;
  if (counties == null || counties.isEmpty) {
    throw AppException('No county data found for this location.');
  }
  final countyData = counties[0];

  String? district;
  List? districts;
  for (final entry in geographies.entries) {
    if (entry.key.toString().contains('Congressional Districts') && entry.value is List) {
      districts = entry.value as List;
      break;
    }
  }
  if (districts == null || districts.isEmpty) {
    debugPrint(
      'parseCensusResponse: no congressional district layer for '
      'lat=$lat, lng=$lng. Layers returned: ${geographies.keys}',
    );
  } else {
    final first = districts[0];
    if (first is Map) {
      final cdKey = first.keys.firstWhere(
        (k) => RegExp(r'^CD\d+$').hasMatch(k.toString()),
        orElse: () => null,
      );
      final raw = cdKey == null ? null : first[cdKey]?.toString();
      district = raw == null ? null : int.tryParse(raw)?.toString();
    }
  }

  return LocationInfo(
    county: countyData['NAME'].toString(),
    state: stateData['NAME'].toString(),
    stateAbbr: stateData['STUSAB'].toString(),
    congressionalDistrict: district,
    lat: lat,
    lng: lng,
  );
}

typedef AddressMatch = ({double lat, double lng, String matched});

/// Looks up a street address and returns every match the Census geocoder
/// finds (best first), so the address picker can offer them as suggestions.
/// Returns an empty list when nothing matches; throws [AppException] when the
/// service can't be reached. (Street addresses only; the Census service does
/// not accept a bare ZIP code.)
Future<List<AddressMatch>> searchAddresses(String address) async {
  final trimmed = address.trim();
  if (trimmed.length < 6) throw AppException('Enter a full street address, including city and state.');
  final url = Uri.https('geocoding.geo.census.gov', '/geocoder/locations/onelineaddress', {
    'address': trimmed,
    'benchmark': 'Public_AR_Current',
    'format': 'json',
  });
  final data = await getJson(url, service: 'The Census geocoder');
  return parseAddressMatches(data, trimmed);
}

/// Reads a Census "onelineaddress" response into a list of matches (pure, so
/// it can be unit tested). Entries without usable coordinates are skipped.
List<AddressMatch> parseAddressMatches(dynamic data, String typed) {
  final result = data is Map ? data['result'] : null;
  final rawMatches = result is Map ? result['addressMatches'] : null;
  if (rawMatches is! List) return const [];
  final matches = <AddressMatch>[];
  for (final m in rawMatches) {
    if (m is! Map) continue;
    final coords = m['coordinates'];
    final x = coords is Map ? coords['x'] : null;
    final y = coords is Map ? coords['y'] : null;
    if (x is! num || y is! num) continue;
    matches.add((
      lat: y.toDouble(),
      lng: x.toDouble(),
      matched: m['matchedAddress']?.toString() ?? typed,
    ));
  }
  return matches;
}

/// Finds coordinates for a street address (the best match). Tries the Census
/// geocoder first and, if it finds nothing or can't be reached, falls back to
/// OpenStreetMap's Nominatim, which is more forgiving of typos, ZIP-only
/// input and unusual formats. Used when the user submits what they typed
/// without picking a suggestion.
Future<AddressMatch> geocodeAddress(String address) async {
  AppException? censusError;
  try {
    final matches = await searchAddresses(address);
    if (matches.isNotEmpty) return matches.first;
  } on AppException catch (e) {
    censusError = e;
  }
  try {
    final fallback = await _searchNominatim(address);
    if (fallback.isNotEmpty) return fallback.first;
  } on AppException catch (e) {
    throw censusError ?? e;
  }
  throw censusError ??
      AppException("We couldn't find that address. Check the spelling and include the city and state.");
}

Future<List<AddressMatch>> _searchNominatim(String address) async {
  final url = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': address.trim(),
    'format': 'jsonv2',
    'countrycodes': 'us',
    'limit': '1',
  });
  // Nominatim's usage policy asks apps to identify themselves.
  final data = await getJson(
    url,
    headers: {'User-Agent': 'CivicRoute/1.0 (Flutter app)'},
    service: 'The address lookup service',
  );
  return parseNominatimMatches(data, address);
}

/// Reads a Nominatim search response (a JSON list) into matches (pure, unit tested).
List<AddressMatch> parseNominatimMatches(dynamic data, String typed) {
  if (data is! List) return const [];
  final matches = <AddressMatch>[];
  for (final m in data) {
    if (m is! Map) continue;
    final lat = double.tryParse(m['lat']?.toString() ?? '');
    final lng = double.tryParse(m['lon']?.toString() ?? '');
    if (lat == null || lng == null) continue;
    matches.add((lat: lat, lng: lng, matched: m['display_name']?.toString() ?? typed));
  }
  return matches;
}
