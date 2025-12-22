import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_account/src/flutter_account_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Shows create account on first launch', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const FlutterAccountApp());
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
  });
}
