/// Tests for the resolver: county directory lookups, plus an optional live
/// test of the full pipeline (coordinates, location, House, Senate, state).
///
/// The live test needs your relay address:
/// `flutter test --dart-define=API_BASE_URL=https://your-relay.workers.dev`
library;

import 'package:civic_route/config.dart';
import 'package:civic_route/models/location_info.dart';
import 'package:civic_route/services/location_service.dart';
import 'package:civic_route/services/resolver_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a LocationInfo for the given county and state abbreviation (district 1, near Towson, MD).
LocationInfo _location(String county, String abbr) => LocationInfo(
      county: county,
      state: 'Somewhere',
      stateAbbr: abbr,
      congressionalDistrict: '1',
      lat: 39.4,
      lng: -76.6,
    );

void main() {
  /// countyKeyFor combines county and state abbreviation into the directory key.
  test('county key includes the state', () {
    expect(countyKeyFor(_location('Baltimore County', 'MD')), 'Baltimore County, MD');
  });

  /// Baltimore County, MD has a directory and contacts; a same-named county in another state does not.
  test('Baltimore County, MD has contacts; same-named counties elsewhere do not', () async {
    final md = _location('Baltimore County', 'MD');
    expect(hasCountyDirectory(md), isTrue);
    expect(await getContactsForIssue('county', md), isNotEmpty);

    final other = _location('Washington County', 'OR');
    expect(hasCountyDirectory(other), isFalse);
    expect(await getContactsForIssue('county', other), isEmpty);
  });

  /// Contacts for the 'county' level are narrowed when an issueId is given.
  test('county contacts are filtered by issue', () async {
    final md = _location('Baltimore County', 'MD');
    final roads = await getContactsForIssue('county', md, issueId: 'local-roads');
    final all = await getContactsForIssue('county', md);
    expect(roads, isNotEmpty);
    expect(roads.length, lessThan(all.length));
  });

  /// With no congressional district, the federal_house lookup returns an empty list instead of failing.
  test('a missing district skips the House lookup instead of failing', () async {
    final noDistrict = LocationInfo(
      county: 'Baltimore County',
      state: 'Maryland',
      stateAbbr: 'MD',
      congressionalDistrict: null,
      lat: 39.4,
      lng: -76.6,
    );
    expect(await getContactsForIssue('federal_house', noDistrict), isEmpty);
  });

  /// Live test of the full pipeline (resolveLocation, then House, Senate and state contacts); skipped without API_BASE_URL.
  test(
    'live: coordinates -> location -> federal and state officials',
    () async {
      final location = await resolveLocation(39.29, -76.61);
      expect(location.stateAbbr, 'MD');
      expect(await getContactsForIssue('federal_house', location), isNotEmpty);
      expect(await getContactsForIssue('federal_senate', location), isNotEmpty);
      expect(await getContactsForIssue('state', location), isNotEmpty);
    },
    skip: AppConfig.hasApi ? null : 'Pass --dart-define=API_BASE_URL=<relay URL> to run live tests.',
  );
}
