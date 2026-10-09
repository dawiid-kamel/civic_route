/// Turns coordinates (or a street address) into county, state and district.
///
/// Calls the free U.S. Census geocoder. `resolveLocation` fetches and
/// `parseCensusResponse` (pure, unit tested) reads the answer. `geocodeAddress`
/// powers "Enter an address instead" for people who don't share GPS.
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

/// Finds coordinates for a street address using the Census geocoder
/// (street addresses only; the Census service does not accept a bare ZIP code).
Future<({double lat, double lng, String matched})> geocodeAddress(String address) async {
  final trimmed = address.trim();
  if (trimmed.length < 6) throw AppException('Enter a full street address, including city and state.');
  final url = Uri.https('geocoding.geo.census.gov', '/geocoder/locations/onelineaddress', {
    'address': trimmed,
    'benchmark': 'Public_AR_Current',
    'format': 'json',
  });
  final data = await getJson(url, service: 'The Census geocoder');
  final result = data is Map ? data["result"] : null;
  final rawMatches = result is Map ? result["addressMatches"] : null;
  final matches = rawMatches is List ? rawMatches : null;
  if (matches == null || matches.isEmpty) {
    throw AppException("We couldn't find that address. Check the spelling and include the city and state.");
  }
  final m = matches.first;
  final coords = m['coordinates'];
  return (
    lat: (coords['y'] as num).toDouble(),
    lng: (coords['x'] as num).toDouble(),
    matched: m['matchedAddress']?.toString() ?? trimmed,
  );
}
