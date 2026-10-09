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
  group('currentCongress', () {
    test('matches the known Congress numbers', () {
      expect(currentCongress(DateTime(2025, 1, 3)), 119);
      expect(currentCongress(DateTime(2026, 10, 7)), 119);
      expect(currentCongress(DateTime(2027, 1, 3)), 120);
      expect(currentCongress(DateTime(2028, 6, 1)), 120);
      expect(currentCongress(DateTime(2029, 1, 3)), 121);
    });

    test('stays on the old Congress until it ends on January 3', () {
      expect(currentCongress(DateTime(2027, 1, 1)), 119);
      expect(currentCongress(DateTime(2027, 1, 2)), 119);
    });
  });

  group('memberChamber', () {
    test('reads the latest term from a list of terms', () {
      final member = {
        'terms': [
          {'chamber': 'House of Representatives'},
          {'chamber': 'Senate'},
        ],
      };
      expect(memberChamber(member), 'Senate');
    });

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

    test('returns null for missing or odd data', () {
      expect(memberChamber(null), isNull);
      expect(memberChamber({'terms': []}), isNull);
      expect(memberChamber({'terms': 'nope'}), isNull);
    });
  });

  test(
    'live: fetchFederalReps returns a Maryland district 1 rep',
    () async {
      final reps = await fetchFederalReps('MD', '1');
      expect(reps, isNotEmpty);
    },
    skip: AppConfig.hasApi ? null : 'Pass --dart-define=API_BASE_URL=<relay URL> to run live tests.',
  );
}
