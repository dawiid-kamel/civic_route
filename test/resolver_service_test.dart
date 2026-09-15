import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civic_route/services/location_service.dart';
import 'package:civic_route/services/resolver_service.dart';

void main() {
  test('full pipeline: coordinates -> location -> federal house rep', () async {
    await dotenv.load(fileName: ".env");

    // Baltimore coordinates as a placeholder — swap in your real ones if you want
    const lat = 39.29;
    const lng = -76.61;

    print("Resolving location for ($lat, $lng)...");
    final location = await resolveLocation(lat, lng);

    print("County: ${location.county}");
    print("State: ${location.state} (${location.stateAbbr})");
    print("Congressional District: ${location.congressionalDistrict}");

    expect(location.county, isNotEmpty);
    expect(location.stateAbbr, isNotEmpty);

    print("\nFetching federal House rep...");
    final houseReps = await getContactsForIssue('federal_house', location);

    for (var rep in houseReps) {
      print("---");
      print("Name: ${rep.name}");
      print("Phone: ${rep.phone}");
      print("Website: ${rep.website}");
    }

    expect(houseReps, isNotEmpty);

    print("\nFetching federal senators...");
    final senators = await getContactsForIssue('federal_senate', location);

    for (var sen in senators) {
      print("---");
      print("Name: ${sen.name}");
      print("Phone: ${sen.phone}");
      print("Website: ${sen.website}");
    }

    expect(senators, isNotEmpty);

    print("\nFetching state legislators...");
    final stateReps = await getContactsForIssue('state', location);

    for (var rep in stateReps) {
      print("---");
      print("Name: ${rep.name}");
      print("Office: ${rep.office}");
    }

    expect(stateReps, isNotEmpty);
  });
}
