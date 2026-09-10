import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/views/main_screen.dart';

void main() {
  testWidgets(
      'Toasts appear above Floating Action Button and FAB never moves or floats on add, edit, or delete',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MainScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Capture initial FAB location
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    final initialFabCenter = tester.getCenter(fabFinder);

    // 2. Open Add Transaction Modal via FAB
    await tester.tap(fabFinder);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('LOG TRANSACTION'), findsOneWidget);

    // Switch to Income (defaults category to Salary)
    await tester.tap(find.text('💰 Income'));
    await tester.pump(const Duration(milliseconds: 100));

    // Enter Amount
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '1500');
    await tester.pump(const Duration(milliseconds: 100));

    // Submit Transaction
    await tester.tap(find.text('LOG INCOME'));
    await tester.pump(const Duration(milliseconds: 300));

    // 3. Verify Toast is visible
    final toastFinder = find.text('Transaction recorded successfully!');
    expect(toastFinder, findsOneWidget);

    // Verify Toast is strictly ABOVE the Floating Action Button (smaller Y means higher on screen)
    final toastCenter = tester.getCenter(toastFinder);
    expect(
      toastCenter.dy,
      lessThan(initialFabCenter.dy),
      reason: 'Toast must appear above the Floating Action Button',
    );

    // Verify FAB has NOT moved or floated at all!
    final fabCenterAfterAdd = tester.getCenter(fabFinder);
    expect(
      fabCenterAfterAdd,
      equals(initialFabCenter),
      reason: 'Floating Action Button must not float or change its position',
    );

    // 4. Test Edit Transaction
    expect(find.text('Salary'), findsWidgets);
    final editButton = find.byTooltip('Edit Transaction');
    expect(editButton, findsOneWidget);

    await tester.tap(editButton);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify modal is in EDIT mode
    expect(find.text('EDIT TRANSACTION'), findsOneWidget);
    expect(find.text('UPDATE TRANSACTION'), findsOneWidget);

    // Change amount to 2500
    final editTextFields = find.byType(TextField);
    await tester.enterText(editTextFields.first, '2500');
    await tester.pump(const Duration(milliseconds: 100));

    // Submit update
    await tester.ensureVisible(find.text('UPDATE TRANSACTION'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('UPDATE TRANSACTION'));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Toast for update
    final updateToast = find.text('Transaction updated successfully!');
    expect(updateToast, findsOneWidget);
    final updateToastCenter = tester.getCenter(updateToast);
    expect(updateToastCenter.dy, lessThan(initialFabCenter.dy));

    final fabCenterAfterEdit = tester.getCenter(fabFinder);
    expect(fabCenterAfterEdit, equals(initialFabCenter));

    // 5. Test Delete Transaction
    final deleteButton = find.byTooltip('Delete Transaction');
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Delete Transaction?'), findsOneWidget);

    // Confirm delete
    await tester.tap(find.text('DELETE'));
    await tester.pump(const Duration(milliseconds: 600));

    // Verify delete toast appears above FAB and FAB is still stationary
    final deleteToast = find.text('Transaction deleted');
    expect(deleteToast, findsOneWidget);
    final deleteToastCenter = tester.getCenter(deleteToast);
    expect(deleteToastCenter.dy, lessThan(initialFabCenter.dy));

    final fabCenterAfterDelete = tester.getCenter(fabFinder);
    expect(fabCenterAfterDelete, equals(initialFabCenter));
  });
}
