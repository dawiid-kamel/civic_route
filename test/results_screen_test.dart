/// Widget tests for the Results screen states (supported county, unsupported
/// county, error with retry) and the Onboarding "skip" path into Home.
///
/// The resolved location is pre-seeded in SharedPreferences, which is exactly
/// what the app stores after a successful lookup, so no network is needed.
library;

import 'dart:convert';

import 'package:civic_route/models/issue.dart';
import 'package:civic_route/screens/home_screen.dart';
import 'package:civic_route/screens/onboarding_screen.dart';
import 'package:civic_route/screens/results_screen.dart';
import 'package:civic_route/services/congress_number.dart';
import 'package:civic_route/services/resolver_service.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test coordinates, matching the position the app would have saved.
const _lat = 39.4;
const _lng = -76.6;

/// SharedPreferences contents for a previously resolved location in the given county/state,
/// so the Results screen can load it without any network call.
Map<String, Object> _seed(String county, String abbr) => {
      'lat': _lat,
      'lng': _lng,
      'resolved_location': jsonEncode({
        'key': '${_lat.toStringAsFixed(3)},${_lng.toStringAsFixed(3)}',
        'congress': currentCongress(),
        'location': {
          'county': county,
          'state': 'Somewhere',
          'stateAbbr': abbr,
          'district': '1',
          'lat': _lat,
          'lng': _lng,
        },
      }),
    };

/// A county-level issue (local roads) used by the Results screen tests.
final _countyIssue = Issue(
  id: 'local-roads',
  name: 'Local roads & potholes',
  levels: ['county'],
  description: 'City or county public works',
);

/// Pumps [screen] in a MaterialApp on a tall 800x3000 surface and waits for it to settle.
Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(800, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

/// Makes the location plugin answer immediately ("location services are off")
/// instead of relying on a missing plugin, whose reply arrives in real time and
/// is not waited for by the test clock.
void _mockLocationOff() {
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in const [
    'flutter.baseflow.com/geolocator',
    'flutter.baseflow.com/geolocator_apple',
    'flutter.baseflow.com/geolocator_android',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => call.method == 'isLocationServiceEnabled' ? false : null,
    );
  }
}

void main() {
  // Each test starts with no remembered location and with location services off.
  setUp(() {
    resetLocationCache();
    _mockLocationOff();
  });

  /// Baltimore County (supported): shows an office, the confirm-with-office disclaimer, and no 'not supported' card.
  testWidgets('supported county shows offices, the disclaimer and no "not supported" card', (tester) async {
    SharedPreferences.setMockInitialValues(_seed('Baltimore County', 'MD'));
    await _pump(tester, ResultsScreen(issue: _countyIssue));

    expect(find.text('BaltCo 311'), findsOneWidget);
    expect(find.textContaining("aren't in Civic Route yet"), findsNothing);
    expect(find.textContaining('Confirm with the office'), findsOneWidget);
  });

  /// Washington County, OR (unsupported): shows the fallback card with Call 211 and the USA.gov link.
  testWidgets('unsupported county shows the fallback card with 211 and USA.gov', (tester) async {
    SharedPreferences.setMockInitialValues(_seed('Washington County', 'OR'));
    await _pump(tester, ResultsScreen(issue: _countyIssue));

    expect(find.textContaining("aren't in Civic Route yet"), findsOneWidget);
    expect(find.text('Call 211'), findsOneWidget);
    expect(find.text('Find your local government'), findsOneWidget);
    expect(find.text('No contacts found yet'), findsNothing);
  });

  /// If the location lookup fails, a friendly message with 'Try again' appears, not raw exception text.
  testWidgets('a failed lookup shows a friendly message and a retry button', (tester) async {
    // No saved position and location services off: the lookup fails.
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, ResultsScreen(issue: _countyIssue));

    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing); // no raw error text
  });

  /// On Onboarding, tapping "I'll do this later" navigates to HomeScreen.
  testWidgets('onboarding "I\'ll do this later" continues to Home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, OnboardingScreen());

    expect(find.text('Enter an address instead'), findsOneWidget);
    await tester.tap(find.text("I'll do this later"));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
