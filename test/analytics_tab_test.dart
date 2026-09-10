import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/transaction_item.dart';
import 'package:perfinax/models/user_profile.dart';
import 'package:perfinax/services/pdf_statement_service.dart';
import 'package:perfinax/views/analytics/analytics_tab.dart';

void main() {
  testWidgets('AnalyticsTab renders Monthly Analytics, Summary, Income Sources, and Expense Breakdown',
      (WidgetTester tester) async {
    final dataController = DataController();
    dataController.userProfile = UserProfile(
      name: 'John Doe',
      occupation: 'Software Engineer',
      phone: '+8801700000000',
      address: 'Dhaka, Bangladesh',
      primaryBank: 'BRAC Bank',
      secondaryBank: 'City Bank',
      mfs: 'bKash',
    );

    // Selected month: October 2026 (selectedMonth = 9 -> month = 10)
    dataController.transactions = [
      TransactionItem(
        id: '1',
        type: 'income',
        amount: 48000.0,
        category: 'Salary',
        date: DateTime(2026, 10, 5),
        account: 'primary',
        note: 'Monthly salary',
        recurring: false,
      ),
      TransactionItem(
        id: '2',
        type: 'income',
        amount: 20000.0,
        category: 'Gift/Bonus',
        date: DateTime(2026, 10, 10),
        account: 'primary',
        note: 'Festival bonus',
        recurring: false,
      ),
      TransactionItem(
        id: '3',
        type: 'expense',
        amount: 5689.0,
        category: 'Loan Pay',
        date: DateTime(2026, 10, 12),
        account: 'primary',
        note: 'Loan installment',
        recurring: false,
      ),
      TransactionItem(
        id: '4',
        type: 'expense',
        amount: 1000.0,
        category: 'Transport',
        date: DateTime(2026, 10, 15),
        account: 'cash',
        note: 'Fuel & Uber',
        recurring: false,
      ),
      TransactionItem(
        id: '5',
        type: 'expense',
        amount: 254.0,
        category: 'Bills',
        date: DateTime(2026, 10, 18),
        account: 'mfs',
        note: 'Internet bill',
        recurring: false,
      ),
      TransactionItem(
        id: '6',
        type: 'saving',
        amount: 4000.0,
        category: 'Emergency Savings',
        date: DateTime(2026, 10, 20),
        account: 'secondary',
        note: 'Deposit',
        recurring: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalyticsTab(
            dataController: dataController,
            selectedYear: 2026,
            selectedMonth: 9, // October
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header section
    expect(find.text('MONTHLY ANALYTICS'), findsOneWidget);
    expect(find.text('Statement and category reports for selected month.'),
        findsOneWidget);
    expect(find.text('Print Statement'), findsOneWidget);

    // 2. Verify Monthly Financial Summary
    expect(find.text('MONTHLY FINANCIAL SUMMARY'), findsOneWidget);
    expect(find.text('Total Income'), findsOneWidget);
    expect(find.text('+৳68000.00'), findsNWidgets(2)); // in Monthly Summary and Yearly Income
    expect(find.text('Total Expense'), findsOneWidget);
    expect(find.text('-৳6943.00'), findsNWidgets(2)); // in Monthly Summary and Yearly Expense
    expect(find.text('Total Savings/Investments'), findsOneWidget);
    expect(find.text('৳4000.00'), findsNWidgets(2)); // in Monthly Summary and Yearly Savings
    expect(find.text('Net Monthly Flow'), findsOneWidget);
    // Net Flow = 68000 - 6943 - 4000 = 57057.00
    expect(find.text('৳57057.00'), findsNWidgets(2)); // in Monthly Summary and Yearly Net Balance

    // 3. Verify Monthly Income Sources
    expect(find.text('MONTHLY INCOME SOURCES'), findsOneWidget);
    expect(find.text('Salary'), findsNWidgets(2)); // in Monthly Income Sources and Yearly Income Earned
    expect(find.text('+৳48000.00 (70.6%)'), findsNWidgets(2));
    expect(find.text('Gift/Bonus'), findsNWidgets(2)); // in Monthly Income Sources and Yearly Income Earned
    expect(find.text('+৳20000.00 (29.4%)'), findsNWidgets(2));

    // 4. Verify Monthly Expense Breakdown
    expect(find.text('MONTHLY EXPENSE BREAKDOWN'), findsOneWidget);
    expect(find.text('Loan Pay'), findsNWidgets(3)); // in breakdown, pie chart legend, and Yearly Expense Spent
    expect(find.text('-৳5689.00 (81.9%)'), findsNWidgets(2));
    expect(find.text('Transport'), findsNWidgets(3)); // in breakdown, pie chart legend, and Yearly Expense Spent
    expect(find.text('-৳1000.00 (14.4%)'), findsNWidgets(2));
    expect(find.text('Bills'), findsNWidgets(3)); // in breakdown, pie chart legend, and Yearly Expense Spent
    expect(find.text('-৳254.00 (3.7%)'), findsNWidgets(2));

    // 5. Verify Monthly Expense Pie Chart and Visual Distribution badge
    expect(find.text('MONTHLY EXPENSE PIE CHART'), findsOneWidget);
    expect(find.text('Visual Distribution'), findsOneWidget);

    // 6. Verify Monthly Expense Comparison Chart section
    expect(find.text('MONTHLY EXPENSE COMPARISON CHART'), findsOneWidget);
    expect(find.text('Expense'), findsWidgets);

    // 7. Verify Year Report section
    expect(find.text('YEAR REPORT'), findsOneWidget);
    expect(find.text('YEARLY INCOME'), findsOneWidget);
    expect(find.text('YEARLY EXPENSE'), findsOneWidget);
    expect(find.text('YEARLY SAVINGS'), findsOneWidget);
    expect(find.text('YEARLY NET BALANCE'), findsOneWidget);

    // Verify the 3 new sections under Year Report
    expect(find.text('YEARLY INCOME VS EXPENSE COMPARISON'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('YEARLY INCOME EARNED'), findsOneWidget);
    expect(find.text('YEARLY EXPENSE SPENT'), findsOneWidget);

    // 8. Test tapping Print Statement opens statement sheet
    await tester.tap(find.text('Print Statement'));
    await tester.pumpAndSettle();

    expect(find.text('MONTHLY FINANCIAL STATEMENT'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('Annual Report: 2026'), findsOneWidget);
    expect(find.text('MONTHLY SUMMARY (October 2026)'), findsOneWidget);

    // Scroll inside the modal's ListView to see Annual Report Summary
    await tester.scrollUntilVisible(
      find.text('ANNUAL REPORT SUMMARY (2026)'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('ANNUAL REPORT SUMMARY (2026)'), findsOneWidget);

    // Scroll to action buttons
    await tester.scrollUntilVisible(
      find.text('Download PDF'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Download PDF'), findsOneWidget);
    expect(find.text('Copy Statement'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsWidgets);

    await tester.tap(find.text('Copy Statement'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Comprehensive Statement for October 2026 & 2026 copied to clipboard!'),
        findsOneWidget);
  });

  testWidgets('AnalyticsTab allows switching Year in Year Report dropdown',
      (WidgetTester tester) async {
    final dataController = DataController();
    dataController.transactions = [
      TransactionItem(
        id: '1',
        type: 'income',
        amount: 50000.0,
        category: 'Salary',
        date: DateTime(2025, 5, 1),
        account: 'primary',
        note: '2025 salary',
        recurring: false,
      ),
      TransactionItem(
        id: '2',
        type: 'expense',
        amount: 3000.0,
        category: 'Bills',
        date: DateTime(2025, 5, 10),
        account: 'primary',
        note: '2025 bill',
        recurring: false,
      ),
      TransactionItem(
        id: '3',
        type: 'expense',
        amount: 6943.0,
        category: 'Loan Pay',
        date: DateTime(2026, 9, 15),
        account: 'primary',
        note: '2026 expense',
        recurring: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalyticsTab(
            dataController: dataController,
            selectedYear: 2026,
            selectedMonth: 8, // September
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to YEAR REPORT section
    await tester.scrollUntilVisible(
      find.text('YEAR REPORT'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('YEAR REPORT'), findsOneWidget);
    expect(find.text('2026'), findsWidgets);

    // Tap Year dropdown in Year Report
    await tester.tap(find.text('2026').first);
    await tester.pumpAndSettle();

    // Select 2025
    await tester.tap(find.text('2025').last);
    await tester.pumpAndSettle();

    // Now Yearly Income for 2025 should be +৳50000.00 and Yearly Expense should be -৳3000.00
    expect(find.text('+৳50000.00'), findsOneWidget);
    expect(find.text('-৳3000.00'), findsOneWidget);
  });

  testWidgets(
      'Year Report renders comparison chart, yearly income earned, and yearly expense spent matching user screenshot scenario',
      (WidgetTester tester) async {
    final dataController = DataController();
    dataController.transactions = [
      TransactionItem(
        id: '1',
        type: 'income',
        amount: 40000.0,
        category: 'Salary',
        date: DateTime(2026, 9, 1),
        account: 'primary',
        note: 'Monthly salary',
        recurring: false,
      ),
      TransactionItem(
        id: '2',
        type: 'expense',
        amount: 9000.0,
        category: 'Rent',
        date: DateTime(2026, 9, 2),
        account: 'primary',
        note: 'House rent',
        recurring: false,
      ),
      TransactionItem(
        id: '3',
        type: 'expense',
        amount: 5000.0,
        category: 'Entertainment',
        date: DateTime(2026, 9, 5),
        account: 'primary',
        note: 'Concert & Outing',
        recurring: false,
      ),
      TransactionItem(
        id: '4',
        type: 'expense',
        amount: 1000.0,
        category: 'Transport',
        date: DateTime(2026, 9, 10),
        account: 'cash',
        note: 'Fuel',
        recurring: false,
      ),
      TransactionItem(
        id: '5',
        type: 'expense',
        amount: 500.0,
        category: 'Bills',
        date: DateTime(2026, 9, 12),
        account: 'mfs',
        note: 'Electric bill',
        recurring: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnalyticsTab(
            dataController: dataController,
            selectedYear: 2026,
            selectedMonth: 8, // September
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll to YEARLY EXPENSE SPENT
    await tester.scrollUntilVisible(
      find.text('YEARLY EXPENSE SPENT'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Section 1: YEARLY INCOME VS EXPENSE COMPARISON
    expect(find.text('YEARLY INCOME VS EXPENSE COMPARISON'), findsOneWidget);

    // Verify Section 2: YEARLY INCOME EARNED
    expect(find.text('YEARLY INCOME EARNED'), findsOneWidget);
    expect(find.text('+৳40000.00 (100.0%)'), findsWidgets);

    // Verify Section 3: YEARLY EXPENSE SPENT
    expect(find.text('YEARLY EXPENSE SPENT'), findsOneWidget);
    expect(find.text('-৳9000.00 (58.1%)'), findsWidgets);
    expect(find.text('-৳5000.00 (32.3%)'), findsWidgets);
    expect(find.text('-৳1000.00 (6.5%)'), findsWidgets);
    expect(find.text('-৳500.00 (3.2%)'), findsWidgets);
  });

  test('PdfStatementService generates valid PDF document bytes with all reports',
      () async {
    final user = UserProfile(
      name: 'John Doe',
      occupation: 'Software Engineer',
      phone: '+8801700000000',
      address: 'Dhaka, Bangladesh',
      primaryBank: 'BRAC Bank',
      secondaryBank: 'City Bank',
      mfs: 'bKash',
    );

    final transactions = [
      TransactionItem(
        id: '1',
        type: 'income',
        amount: 40000.0,
        category: 'Salary',
        date: DateTime(2026, 9, 1),
        account: 'primary',
        note: 'September salary',
        recurring: false,
      ),
      TransactionItem(
        id: '2',
        type: 'expense',
        amount: 9000.0,
        category: 'Rent',
        date: DateTime(2026, 9, 2),
        account: 'primary',
        note: 'Flat rent',
        recurring: false,
      ),
    ];

    final pdfBytes = await PdfStatementService.generateStatementPdf(
      user: user,
      periodTxs: transactions,
      selectedMonth: 8,
      selectedYear: 2026,
      totalIncome: 40000.0,
      totalExpense: 9000.0,
      totalSavings: 5000.0,
      netMonthlyFlow: 26000.0,
      sortedIncomeEntries: [const MapEntry('Salary', 40000.0)],
      sortedExpenseEntries: [const MapEntry('Rent', 9000.0)],
      selectedReportYear: 2026,
      yearlyIncome: 40000.0,
      yearlyExpense: 9000.0,
      yearlySavings: 5000.0,
      yearlyNetBalance: 26000.0,
      yearlyMonthlyIncomes: List.filled(12, 0.0)..[8] = 40000.0,
      yearlyMonthlyExpenses: List.filled(12, 0.0)..[8] = 9000.0,
      sortedYearlyIncomeEntries: [const MapEntry('Salary', 40000.0)],
      sortedYearlyExpenseEntries: [const MapEntry('Rent', 9000.0)],
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.isNotEmpty, isTrue);
    // Standard PDF header signature starts with '%PDF-' (0x25, 0x50, 0x44, 0x46, 0x2D)
    expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
  });
}

