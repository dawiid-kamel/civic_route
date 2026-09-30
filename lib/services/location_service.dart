import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_info.dart';

Future<LocationInfo> resolveLocation(double lat, double lng) async {
  // Auto-correct an obvious sign mistake: US longitudes are always negative
  if (lng > 0 && lng < 180) {
    lng = -lng;
  }

  final url = Uri.parse(
    'https://geocoding.geo.census.gov/geocoder/geographies/coordinates'
    '?x=$lng&y=$lat&benchmark=Public_AR_Current&vintage=Current_Current&format=json'
  );

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Census API failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  final geographies = data['result']['geographies'];

  final states = geographies['States'] as List?;
  if (states == null || states.isEmpty) {
    throw Exception('No US location found for these coordinates. Please check your latitude/longitude.');
  }
  final stateData = states[0];

  final counties = geographies['Counties'] as List?;
  if (counties == null || counties.isEmpty) {
    throw Exception('No county data found for these coordinates.');
  }
  final countyData = counties[0];

  final districts = geographies['119th Congressional Districts'] as List?;
  // This used to throw and take down the ENTIRE location lookup — meaning
  // even a county- or state-only issue (which never needs a House district)
  // would fail with "No congressional district found," as you just saw.
  // Now a missing district only affects House-rep lookups specifically;
  // everything else still works.
  String? district;
  if (districts == null || districts.isEmpty) {
    // ignore: avoid_print
    print(
      'resolveLocation: no "119th Congressional Districts" entry for '
      'lat=$lat, lng=$lng. Geography layers actually returned by the '
      'Census API: ${geographies.keys}',
    );
  } else {
    final rawDistrict = districts[0]['CD119'] as String;
    district = int.parse(rawDistrict).toString();
  }

  return LocationInfo(
    county: countyData['NAME'],
    state: stateData['NAME'],
    stateAbbr: stateData['STUSAB'],
    congressionalDistrict: district,
    lat: lat,
    lng: lng,
  );
}