// Smoke test: boots Fridgenie in demo mode and checks the splash wordmark.

import 'package:flutter_test/flutter_test.dart';
import 'package:fridgenie/data/storage/local_store.dart';
import 'package:fridgenie/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Fridgenie boots and renders the wordmark on splash',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();

    await tester.pumpWidget(FridgenieApp(store: store));
    await tester.pump();

    expect(find.text('Fridgenie'), findsWidgets);
  });
}
