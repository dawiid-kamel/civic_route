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
  if (districts == null || districts.isEmpty) {
    throw Exception('No congressional district found for these coordinates.');
  }
  final districtData = districts[0];

  final rawDistrict = districtData['CD119'] as String;
  final district = int.parse(rawDistrict).toString();

  return LocationInfo(
    county: countyData['NAME'],
    state: stateData['NAME'],
    stateAbbr: stateData['STUSAB'],
    congressionalDistrict: district,
    lat: lat,
    lng: lng,
  );
}
