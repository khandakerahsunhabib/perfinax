import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perfinax/controllers/theme_controller.dart';
import 'package:perfinax/views/main_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeController toggleTheme toggles between dark and light modes', () async {
    final controller = ThemeController.instance;
    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.isDarkMode, isTrue);

    await controller.toggleTheme();
    expect(controller.isDarkMode, isFalse);
    expect(controller.themeMode, equals(ThemeMode.light));

    await controller.toggleTheme();
    expect(controller.isDarkMode, isTrue);
    expect(controller.themeMode, equals(ThemeMode.dark));
  });

  testWidgets('Clicking theme toggle icon in AppBar toggles theme automatically without modal',
      (WidgetTester tester) async {
    final controller = ThemeController.instance;
    await controller.setThemeMode(ThemeMode.dark);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify dark mode theme icon is present with tooltip
    final lightModeTooltipFinder = find.byTooltip('Switch to Light Mode');
    expect(lightModeTooltipFinder, findsOneWidget);

    // Tap the icon
    await tester.tap(lightModeTooltipFinder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Theme should now be light mode
    expect(controller.isDarkMode, isFalse);

    // Verify light mode theme icon is now present with tooltip to switch back to dark
    final darkModeTooltipFinder = find.byTooltip('Switch to Dark Mode');
    expect(darkModeTooltipFinder, findsOneWidget);

    // Verify no bottom sheet modal was opened
    expect(find.byType(BottomSheet), findsNothing);

    // Tap again to switch back to dark mode
    await tester.tap(darkModeTooltipFinder);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.isDarkMode, isTrue);
  });
}
