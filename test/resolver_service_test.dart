/// Tests for the resolver: county directory lookups, plus an optional live
/// test of the full pipeline (coordinates, location, House, Senate, state).
///
/// The live test needs both API keys:
/// `flutter test --dart-define=CONGRESS_API_KEY=... --dart-define=OPENSTATES_API_KEY=...`
library;

import 'package:civic_route/config.dart';
import 'package:civic_route/data/issue_tree.dart';
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

  /// The "local coverage" notices read the covered counties from the directory.
  test('coveredCountiesText lists the counties in the directory', () {
    expect(coveredCountiesText(), contains('Baltimore County, MD'));
  });

  /// Offices built for the exact issue come first, so street lights lead with BGE.
  test('issue-specific offices are listed before general ones', () async {
    final md = _location('Baltimore County', 'MD');
    final lights = await getContactsForIssue('county', md, issueId: 'streetlights');
    expect(lights.first.name, 'BGE Customer Care');
    expect(lights.first.phone, '800-685-0123');
    // General offices (County Executive, 311, ...) still follow.
    expect(lights.any((c) => c.issueIds.isEmpty), isTrue);
    expect(lights.indexWhere((c) => c.issueIds.isEmpty), greaterThan(0));

    final strays = await getContactsForIssue('county', md, issueId: 'stray-animals');
    expect(strays.first.name, 'Baltimore County Animal Services');
    expect(strays.first.phone, '410-887-7297');
  });

  /// Every county-level issue has at least one office built specifically for it.
  test('every county issue has a specific office', () async {
    final md = _location('Baltimore County', 'MD');
    for (final cat in issueTree) {
      for (final issue in cat.subIssues.where((i) => i.levels.contains('county'))) {
        final contacts = await getContactsForIssue('county', md, issueId: issue.id);
        expect(contacts.any((c) => c.issueIds.contains(issue.id)), isTrue, reason: issue.id);
      }
    }
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

  /// Live test of the full pipeline (resolveLocation, then House, Senate and state contacts); skipped without the API keys.
  test(
    'live: coordinates -> location -> federal and state officials',
    () async {
      final location = await resolveLocation(39.29, -76.61);
      expect(location.stateAbbr, 'MD');
      expect(await getContactsForIssue('federal_house', location), isNotEmpty);
      expect(await getContactsForIssue('federal_senate', location), isNotEmpty);
      expect(await getContactsForIssue('state', location), isNotEmpty);
    },
    skip: AppConfig.hasApi ? null : 'Pass --dart-define=CONGRESS_API_KEY and OPENSTATES_API_KEY to run live tests.',
  );
}
