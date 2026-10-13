/// Tests for Congress numbering and member parsing, plus an optional live test.
///
/// The offline tests always run. The live test hits the real API through your
/// relay, so it only runs when you pass your relay address:
/// `flutter test --dart-define=API_BASE_URL=https://your-relay.workers.dev`
library;

import 'package:civic_route/config.dart';
import 'package:civic_route/services/congress_number.dart';
import 'package:civic_route/services/congress_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // currentCongress: maps a date to the Congress number (a new one starts on January 3 of odd years).
  group('currentCongress', () {
    /// Spot-checks dates across several Congresses (119th through 121st).
    test('matches the known Congress numbers', () {
      expect(currentCongress(DateTime(2025, 1, 3)), 119);
      expect(currentCongress(DateTime(2026, 10, 7)), 119);
      expect(currentCongress(DateTime(2027, 1, 3)), 120);
      expect(currentCongress(DateTime(2028, 6, 1)), 120);
      expect(currentCongress(DateTime(2029, 1, 3)), 121);
    });

    /// Right before January 3, 2027 the 119th Congress is still current.
    test('stays on the old Congress until it ends on January 3', () {
      expect(currentCongress(DateTime(2027, 1, 1)), 119);
      expect(currentCongress(DateTime(2027, 1, 2)), 119);
    });
  });

  // memberChamber: extracts the chamber name from a Congress.gov member JSON object.
  group('memberChamber', () {
    /// With a plain list of terms, the last (latest) term's chamber is returned.
    test('reads the latest term from a list of terms', () {
      final member = {
        'terms': [
          {'chamber': 'House of Representatives'},
          {'chamber': 'Senate'},
        ],
      };
      expect(memberChamber(member), 'Senate');
    });

    /// Terms may arrive wrapped as {'item': [...]}; that shape is also understood.
    test('reads terms wrapped in an "item" list', () {
      final member = {
        'terms': {
          'item': [
            {'chamber': 'House of Representatives'},
          ],
        },
      };
      expect(memberChamber(member), 'House of Representatives');
    });

    /// Null, an empty term list, or a non-list value yields null instead of throwing.
    test('returns null for missing or odd data', () {
      expect(memberChamber(null), isNull);
      expect(memberChamber({'terms': []}), isNull);
      expect(memberChamber({'terms': 'nope'}), isNull);
    });
  });

  /// Live test of fetchFederalReps('MD', '1'); skipped unless API_BASE_URL is provided.
  test(
    'live: fetchFederalReps returns a Maryland district 1 rep',
    () async {
      final reps = await fetchFederalReps('MD', '1');
      expect(reps, isNotEmpty);
    },
    skip: AppConfig.hasApi ? null : 'Pass --dart-define=API_BASE_URL=<relay URL> to run live tests.',
  );
}
