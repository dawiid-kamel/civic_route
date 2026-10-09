/// Tests for the pure parsing functions: the Census location response and the
/// Open States legislator response. They use small fixtures, so no network.
library;

import 'package:civic_route/services/api_client.dart';
import 'package:civic_route/services/location_service.dart';
import 'package:civic_route/services/state_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('parseCensusResponse', () {
    test('reads county, state and district', () {
      final loc = parseCensusResponse(_census(), 39.4, -76.6);
      expect(loc.county, 'Baltimore County');
      expect(loc.state, 'Maryland');
      expect(loc.stateAbbr, 'MD');
      expect(loc.congressionalDistrict, '2'); // leading zero removed
    });

    test('works for a later Congress without any code change', () {
      final loc = parseCensusResponse(
        _census(layer: '120th Congressional Districts', field: 'CD120', cd: '07'),
        39.4,
        -76.6,
      );
      expect(loc.congressionalDistrict, '7');
    });

    test('a missing district layer leaves the district null', () {
      final loc = parseCensusResponse(_census(withDistrict: false), 39.4, -76.6);
      expect(loc.congressionalDistrict, isNull);
      expect(loc.county, 'Baltimore County');
    });

    test('does not flip the sign of a positive longitude', () {
      final loc = parseCensusResponse(_census(), 13.4, 144.7); // Guam-like input
      expect(loc.lng, 144.7);
    });

    test('rejects locations outside the US with a friendly message', () {
      expect(
        () => parseCensusResponse({'result': {'geographies': {}}}, 0, 0),
        throwsA(isA<AppException>()),
      );
      expect(() => parseCensusResponse(null, 0, 0), throwsA(isA<AppException>()));
    });
  });

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

    test('keeps only state-level people', () {
      final contacts = parseStateLegislators(response);
      expect(contacts.map((c) => c.name), ['Jane Senator', 'Sam Delegate']);
      expect(contacts.every((c) => c.level == 'state'), isTrue);
    });

    test('pulls phone and address from offices', () {
      final jane = parseStateLegislators(response).first;
      expect(jane.phone, '410-841-3000');
      expect(jane.address, contains('Bladen'));
    });

    test('sorts email addresses and links into the right fields', () {
      final contacts = parseStateLegislators(response);
      expect(contacts[0].email, 'jane@mgaleg.maryland.gov');
      expect(contacts[0].website, contains('mgaleg.maryland.gov')); // Maryland fallback
      expect(contacts[1].website, 'https://example.org/contact');
      expect(contacts[1].email, isNull);
    });

    test('handles empty or malformed responses', () {
      expect(parseStateLegislators(null), isEmpty);
      expect(parseStateLegislators({'results': null}), isEmpty);
      expect(parseStateLegislators({}), isEmpty);
    });
  });
}
