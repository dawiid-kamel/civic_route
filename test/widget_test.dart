import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_route/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows dashboard, search, and local alerts', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    expect(find.text('My civic dashboard'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Local alerts'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local alerts'), findsOneWidget);
  });
}
