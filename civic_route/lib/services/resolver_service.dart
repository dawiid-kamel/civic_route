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

Future<List<Contact>> getContactsForIssue(String level, LocationInfo location) async {
  switch (level) {
    case 'federal_house':
      return await fetchFederalReps(location.stateAbbr, location.congressionalDistrict);

    case 'federal_senate':
      return await fetchSenators(location.stateAbbr);

    case 'state':
      return await fetchStateLegislators(location.lat, location.lng);

    case 'county':
      return countyDictionary[location.county] ?? [];

    default:
      return [];
  }
}
