/// Tests for the pure parsing functions: the Census location response and the
/// Open States legislator response. They use small fixtures, so no network.
library;

import 'package:civic_route/services/api_client.dart';
import 'package:civic_route/services/location_service.dart';
import 'package:civic_route/services/state_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a fake Census geocoder response with one state, one county and (optionally) a
/// congressional district under the given layer/field names.
Map<String, dynamic> _census({String layer = '119th Congressional Districts', String field = 'CD119', String cd = '02', bool withDistrict = true}) => {
      'result': {
        'geographies': {
          'States': [
            {'NAME': 'Maryland', 'STUSAB': 'MD'},
          ],
          'Counties': [
            {'NAME': 'Baltimore County'},
          ],
          if (withDistrict)
            layer: [
              {field: cd},
            ],
        },
      },
    };

void main() {
  // parseCensusResponse: turns a Census geographies response into a LocationInfo.
  group('parseCensusResponse', () {
    /// Reads county, state name, state abbreviation and district (leading zero stripped).
    test('reads county, state and district', () {
      final loc = parseCensusResponse(_census(), 39.4, -76.6);
      expect(loc.county, 'Baltimore County');
      expect(loc.state, 'Maryland');
      expect(loc.stateAbbr, 'MD');
      expect(loc.congressionalDistrict, '2'); // leading zero removed
    });

    /// The district is found by layer name, so a newer Congress (CD120) works unchanged.
    test('works for a later Congress without any code change', () {
      final loc = parseCensusResponse(
        _census(layer: '120th Congressional Districts', field: 'CD120', cd: '07'),
        39.4,
        -76.6,
      );
      expect(loc.congressionalDistrict, '7');
    });

    /// With no district layer the district is null, but the county is still read.
    test('a missing district layer leaves the district null', () {
      final loc = parseCensusResponse(_census(withDistrict: false), 39.4, -76.6);
      expect(loc.congressionalDistrict, isNull);
      expect(loc.county, 'Baltimore County');
    });

    /// A positive longitude (east of Greenwich) keeps its sign.
    test('does not flip the sign of a positive longitude', () {
      final loc = parseCensusResponse(_census(), 13.4, 144.7); // Guam-like input
      expect(loc.lng, 144.7);
    });

    /// Responses with no geographies, or null, throw an AppException (location outside the US).
    test('rejects locations outside the US with a friendly message', () {
      expect(
        () => parseCensusResponse({'result': {'geographies': {}}}, 0, 0),
        throwsA(isA<AppException>()),
      );
      expect(() => parseCensusResponse(null, 0, 0), throwsA(isA<AppException>()));
    });
  });

  // parseStateLegislators: turns an Open States people.geo response into Contact objects.
  group('parseStateLegislators', () {
    final response = {
      'results': [
        {
          'name': 'Jane Senator',
          'email': 'jane@mgaleg.maryland.gov',
          'jurisdiction': {'classification': 'state', 'name': 'Maryland'},
          'current_role': {'title': 'Senator'},
          'offices': [
            {'voice': '410-841-3000', 'address': '11 Bladen St, Annapolis'},
          ],
        },
        {
          'name': 'Sam Delegate',
          'email': 'https://example.org/contact',
          'jurisdiction': {'classification': 'state', 'name': 'Maryland'},
          'current_role': {'title': 'Delegate'},
        },
        {
          'name': 'Fed Person',
          'jurisdiction': {'classification': 'country', 'name': 'United States'},
          'current_role': {'title': 'Representative'},
        },
      ],
    };

    /// Entries whose jurisdiction is not 'state' (e.g. a federal person) are dropped.
    test('keeps only state-level people', () {
      final contacts = parseStateLegislators(response);
      expect(contacts.map((c) => c.name), ['Jane Senator', 'Sam Delegate']);
      expect(contacts.every((c) => c.level == 'state'), isTrue);
    });

    /// Phone and address come from the first office entry.
    test('pulls phone and address from offices', () {
      final jane = parseStateLegislators(response).first;
      expect(jane.phone, '410-841-3000');
      expect(jane.address, contains('Bladen'));
    });

    /// An email address goes to email; a URL goes to website; with an email, the Maryland site is the website fallback.
    test('sorts email addresses and links into the right fields', () {
      final contacts = parseStateLegislators(response);
      expect(contacts[0].email, 'jane@mgaleg.maryland.gov');
      expect(contacts[0].website, contains('mgaleg.maryland.gov')); // Maryland fallback
      expect(contacts[1].website, 'https://example.org/contact');
      expect(contacts[1].email, isNull);
    });

    /// Null, null results, or an empty map produce an empty list.
    test('handles empty or malformed responses', () {
      expect(parseStateLegislators(null), isEmpty);
      expect(parseStateLegislators({'results': null}), isEmpty);
      expect(parseStateLegislators({}), isEmpty);
    });
  });
  // parseAddressMatches: turns a Census address-search response into candidate matches.
  group('parseAddressMatches', () {
    /// Wraps a list of address matches in the Census response shape.
    Map<String, dynamic> response(List<Map<String, dynamic>> matches) => {
          'result': {'addressMatches': matches},
        };

    /// Every match with coordinates is returned in order, with matched text, lat (y) and lng (x).
    test('returns every match with coordinates, best first', () {
      final matches = parseAddressMatches(
        response([
          {'matchedAddress': '123 MAIN ST, TOWSON, MD, 21204', 'coordinates': {'x': -76.6, 'y': 39.4}},
          {'matchedAddress': '123 MAIN ST, BALTIMORE, MD, 21201', 'coordinates': {'x': -76.61, 'y': 39.29}},
        ]),
        '123 main st',
      );
      expect(matches.length, 2);
      expect(matches.first.matched, '123 MAIN ST, TOWSON, MD, 21204');
      expect(matches.first.lat, 39.4);
      expect(matches.first.lng, -76.6);
    });

    /// Matches whose coordinates are null are skipped.
    test('skips entries without usable coordinates', () {
      final matches = parseAddressMatches(
        response([
          {'matchedAddress': 'NO COORDS', 'coordinates': null},
          {'matchedAddress': 'GOOD', 'coordinates': {'x': -76.6, 'y': 39.4}},
        ]),
        'x',
      );
      expect(matches.map((m) => m.matched), ['GOOD']);
    });

    /// Null, empty, or missing results produce an empty list.
    test('handles empty or malformed responses', () {
      expect(parseAddressMatches(null, 'x'), isEmpty);
      expect(parseAddressMatches({}, 'x'), isEmpty);
      expect(parseAddressMatches({'result': {'addressMatches': []}}, 'x'), isEmpty);
    });
  });

  // parseNominatimMatches: turns an OpenStreetMap Nominatim result list into candidate matches.
  group('parseNominatimMatches', () {
    /// Coordinates given as strings are parsed; entries with unparseable coordinates are skipped.
    test('reads string coordinates and skips bad entries', () {
      final matches = parseNominatimMatches([
        {'lat': '39.4015', 'lon': '-76.6019', 'display_name': 'Towson, MD'},
        {'lat': 'x', 'lon': '1'},
      ], 'towson');
      expect(matches.length, 1);
      expect(matches.first.lat, 39.4015);
      expect(matches.first.lng, -76.6019);
      expect(matches.first.matched, 'Towson, MD');
    });

    /// Null or a non-list value produces an empty list.
    test('handles malformed responses', () {
      expect(parseNominatimMatches(null, 'x'), isEmpty);
      expect(parseNominatimMatches({'a': 1}, 'x'), isEmpty);
    });
  });
}
