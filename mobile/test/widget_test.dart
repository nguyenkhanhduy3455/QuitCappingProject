import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/app.dart';
import 'package:mobile/core/localization/widgets/language_selector_button.dart';
import 'package:mobile/core/storage/token_storage.dart';

void main() {
  testWidgets('QuitCapping smoke test boots in Vietnamese and switches to English on toggle', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const QuitCappingApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial Vietnamese state
    expect(find.text('QuitCapping'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('VN'), findsOneWidget);

    // Tap language toggle pill on login screen
    await tester.tap(find.byType(LanguageTogglePill));
    await tester.pumpAndSettle();

    // Verify switched to English state
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('Stop capping. Provide real proof.'), findsOneWidget);
  });

  testWidgets('MainNavigationShell renders all 4 tabs in bottom navigation bar', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: MainNavigationShell(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 4 bottom navigation tabs are present
    expect(find.text('Nhiệm vụ'), findsOneWidget);
    expect(find.text('Mục tiêu'), findsOneWidget);
    expect(find.text('Đánh giá chéo'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
  });
}
