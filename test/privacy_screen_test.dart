/// The privacy policy is built into the app, so it must always open and show
/// its main sections without any network access.
library;

import 'package:civic_route/screens/privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('privacy screen shows the policy with no network', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: PrivacyScreen()));

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Where your information goes'), findsOneWidget);
    expect(find.text('What we do not collect'), findsOneWidget);
    expect(find.textContaining('Last updated'), findsOneWidget);
  });
}
