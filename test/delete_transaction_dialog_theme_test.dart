import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/core/constants/app_colors.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/transaction_item.dart';
import 'package:perfinax/views/dashboard/dashboard_tab.dart';

void main() {
  testWidgets(
      'Delete Transaction dialog styles correctly in light and dark theme',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Light Theme Test
    final dataControllerLight = DataController();
    dataControllerLight.transactions = [
      TransactionItem(
        id: 'test-tx-1',
        type: 'expense',
        amount: 250.0,
        category: 'Food',
        date: DateTime(2026, 10, 5),
        account: 'primary',
        note: 'Lunch',
        recurring: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: DashboardTab(
            dataController: dataControllerLight,
            selectedYear: 2026,
            selectedMonth: 9, // October
            homeScrollController: ScrollController(),
            onDataChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap delete button to open dialog
    final deleteBtn = find.byTooltip('Delete Transaction');
    expect(deleteBtn, findsOneWidget);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Verify Title style in light theme
    final titleFinder = find.text('Delete Transaction?');
    expect(titleFinder, findsOneWidget);
    final Text titleWidget = tester.widget(titleFinder);
    expect(titleWidget.style?.color, equals(const Color(0xFF0F172A)));

    // Verify Content style in light theme
    final contentFinder = find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data!
            .startsWith("Are you sure you want to delete this EXPENSE entry"));
    expect(contentFinder, findsOneWidget);
    final Text contentWidget = tester.widget(contentFinder);
    expect(contentWidget.style?.color, equals(const Color(0xFF334155)));

    // Verify Cancel button in light theme
    final cancelBtnFinder = find.widgetWithText(OutlinedButton, 'CANCEL');
    expect(cancelBtnFinder, findsOneWidget);
    final OutlinedButton cancelBtn = tester.widget(cancelBtnFinder);
    expect(cancelBtn.style?.foregroundColor?.resolve({}),
        equals(const Color(0xFF334155)));

    // Verify Delete button in light theme
    final deleteConfirmBtnFinder =
        find.widgetWithText(ElevatedButton, 'DELETE');
    expect(deleteConfirmBtnFinder, findsOneWidget);
    final ElevatedButton deleteConfirmBtn =
        tester.widget(deleteConfirmBtnFinder);
    expect(deleteConfirmBtn.style?.backgroundColor?.resolve({}),
        equals(AppColors.rose));
    expect(deleteConfirmBtn.style?.foregroundColor?.resolve({}),
        equals(Colors.white));

    // Dismiss dialog
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    // 2. Dark Theme Test
    final dataControllerDark = DataController();
    dataControllerDark.transactions = [
      TransactionItem(
        id: 'test-tx-2',
        type: 'expense',
        amount: 350.0,
        category: 'Shopping',
        date: DateTime(2026, 10, 5),
        account: 'primary',
        note: 'Clothes',
        recurring: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: DashboardTab(
            dataController: dataControllerDark,
            selectedYear: 2026,
            selectedMonth: 9, // October
            homeScrollController: ScrollController(),
            onDataChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap delete button in dark theme
    final deleteBtnDark = find.byTooltip('Delete Transaction');
    expect(deleteBtnDark, findsOneWidget);
    await tester.tap(deleteBtnDark);
    await tester.pumpAndSettle();

    // Verify Title style in dark theme (unchanged white)
    final titleFinderDark = find.text('Delete Transaction?');
    expect(titleFinderDark, findsOneWidget);
    final Text titleWidgetDark = tester.widget(titleFinderDark);
    expect(titleWidgetDark.style?.color, equals(Colors.white));

    // Verify Content style in dark theme (unchanged AppColors.slate300)
    final contentFinderDark = find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data != null &&
        widget.data!
            .startsWith("Are you sure you want to delete this EXPENSE entry"));
    expect(contentFinderDark, findsOneWidget);
    final Text contentWidgetDark = tester.widget(contentFinderDark);
    expect(contentWidgetDark.style?.color, equals(AppColors.slate300));

    // Verify Cancel button in dark theme (unchanged white)
    final cancelBtnFinderDark = find.widgetWithText(OutlinedButton, 'CANCEL');
    expect(cancelBtnFinderDark, findsOneWidget);
    final OutlinedButton cancelBtnDark = tester.widget(cancelBtnFinderDark);
    expect(cancelBtnDark.style?.foregroundColor?.resolve({}),
        equals(Colors.white));

    // Verify Delete button in dark theme (unchanged AppColors.rose with white)
    final deleteConfirmBtnFinderDark =
        find.widgetWithText(ElevatedButton, 'DELETE');
    expect(deleteConfirmBtnFinderDark, findsOneWidget);
    final ElevatedButton deleteConfirmBtnDark =
        tester.widget(deleteConfirmBtnFinderDark);
    expect(deleteConfirmBtnDark.style?.backgroundColor?.resolve({}),
        equals(AppColors.rose));
    expect(deleteConfirmBtnDark.style?.foregroundColor?.resolve({}),
        equals(Colors.white));
  });
}
