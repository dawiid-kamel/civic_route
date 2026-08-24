import '../models/contact.dart';
import '../models/location_info.dart';
import 'congress_service.dart';
import 'state_service.dart';
import '../data/county_data.dart';

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
