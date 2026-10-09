/// Widget tests for the Home screen: dashboard, search field, saved topics
/// and the hidden "Local alerts" section.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_route/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows dashboard and search, and hides the unfinished alerts section', (WidgetTester tester) async {
    // HomeScreen reads SharedPreferences; without a mock the plugin call fails in tests.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    expect(find.text('My civic dashboard'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // The quick-search suggestion chips were removed.
    expect(find.text('Pothole'), findsNothing);

    await tester.pumpAndSettle();

    // Local alerts are switched off for launch (AppConfig.enableLocalAlerts),
    // so the section must not appear until a real feed exists.
    expect(find.text('Local alerts'), findsNothing);
  });

  testWidgets('HomeScreen lists saved topics for quick access', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_categories': ['housing'],
      'saved_issues': ['hud'],
    });
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Saved topics'), findsOneWidget);
    // Housing also appears in the category grid, so expect more than one.
    expect(find.text('Housing'), findsWidgets);
    expect(find.text('Federal housing policy (HUD)'), findsOneWidget);
  });
}
