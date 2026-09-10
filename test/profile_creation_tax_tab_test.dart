import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/views/main_screen.dart';

void main() {
  testWidgets(
      'When no profile is created, Profile tab is shown instead of Income TAX, and tapping it shows profile creation screen. After creation, Income TAX tab is shown.',
      (WidgetTester tester) async {
    // Build MainScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Initial State: No profile is created yet
    // The bottom nav 4th tab should be 'Profile'
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Income TAX'), findsNothing);
    expect(find.byIcon(Icons.person_rounded), findsWidgets);
    expect(find.byIcon(Icons.calculate_rounded), findsNothing);

    // 2. Tap the 4th tab ('Profile')
    await tester.tap(find.text('Profile').last);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify profile creation screen is shown
    expect(find.text('CREATE YOUR PROFILE'), findsOneWidget);
    expect(find.text('Welcome to PERFINAX!'), findsOneWidget);
    expect(find.text('CREATE PROFILE'), findsOneWidget);

    // Income tax tab content should NOT be shown
    expect(find.text('Income TAX Calculator'), findsNothing);

    // 3. Fill in the profile name in the creation screen
    final textFields = find.byType(TextField);
    expect(textFields, findsWidgets);

    // Enter full name into the first text field (Full Name)
    await tester.enterText(textFields.first, 'Tanvir Hasan');
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'CREATE PROFILE' button
    await tester.ensureVisible(find.text('CREATE PROFILE'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('CREATE PROFILE'));
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Verification after profile creation:
    // SnackBar should confirm creation and unlocked Income TAX
    expect(
      find.text('Profile created successfully! Income TAX tab is now unlocked.'),
      findsOneWidget,
    );

    // Now the 4th tab must show 'Income TAX'
    expect(find.text('Income TAX'), findsOneWidget);
    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);

    // Screen should now display the Income TAX tab
    expect(find.text('Income TAX Calculator'), findsOneWidget);

    // 5. Test AppBar Profile button navigation
    // AppBar should now show 'Tanvir'
    expect(find.text('Tanvir'), findsOneWidget);

    await tester.tap(find.text('Tanvir'));
    await tester.pump(const Duration(milliseconds: 500));

    // Now ProfileTab is in view/detail mode (showing Profile Details)
    expect(find.text('Tanvir Hasan'), findsWidgets);
    expect(find.text('EDIT PROFILE'), findsOneWidget);

    // Tap back to 'Income TAX' tab from bottom nav
    await tester.tap(find.text('Income TAX'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Income TAX Calculator'), findsOneWidget);
  });
}
