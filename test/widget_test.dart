// Smoke test: boots Fridgenie's splash screen and verifies the wordmark
// renders. The default Flutter counter test was deleted because it referenced
// a non-existent `MyApp` class.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fridgenie/main.dart';
import 'package:fridgenie/providers/user_provider.dart';

void main() {
  testWidgets('Fridgenie boots and renders the wordmark on splash',
      (WidgetTester tester) async {
    final user = UserProvider();
    await tester.pumpWidget(FridgenieApp(userProvider: user));

    // Pump one frame so the splash screen renders.
    await tester.pump();

    expect(find.text('Fridgenie'), findsWidgets);
  });
}
