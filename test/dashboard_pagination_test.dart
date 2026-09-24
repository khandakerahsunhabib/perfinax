import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/transaction_item.dart';
import 'package:perfinax/models/user_profile.dart';
import 'package:perfinax/views/dashboard/dashboard_tab.dart';

void main() {
  testWidgets('DashboardTab Latest Transactions pagination works sequentially and accurately',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dataController = DataController();
    dataController.userProfile = UserProfile(
      name: 'Test User',
      occupation: 'Developer',
      phone: '+8801700000000',
      address: 'Dhaka',
      primaryBank: 'Bank A',
      secondaryBank: 'Bank B',
      mfs: 'bKash',
    );

    // Create 12 transactions in October 2026 (selectedMonth = 9 -> month 10)
    // Dated from Oct 1 to Oct 12
    final List<TransactionItem> testItems = [];
    for (int i = 1; i <= 12; i++) {
      testItems.add(
        TransactionItem(
          id: '100$i',
          type: i % 2 == 0 ? 'income' : 'expense',
          amount: (i * 100).toDouble(),
          category: i % 2 == 0 ? 'Salary' : 'Food & Groceries',
          date: DateTime(2026, 10, i),
          account: 'primary',
          note: 'Tx #$i note',
          recurring: false,
        ),
      );
    }
    dataController.transactions = testItems;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: DashboardTab(
            dataController: dataController,
            selectedYear: 2026,
            selectedMonth: 9, // October
            homeScrollController: ScrollController(),
            onDataChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Latest Transactions header is present
    expect(find.text('LATEST TRANSACTIONS'), findsOneWidget);

    // Default sort is descending by date (latest first): Tx #12 down to Tx #8 on Page 1
    // Page 1 should show: Tx #12, Tx #11, Tx #10, Tx #9, Tx #8
    expect(find.text('Page 1 of 3 (12 items)'), findsOneWidget);
    expect(find.textContaining('Tx #12 note'), findsOneWidget);
    expect(find.textContaining('Tx #11 note'), findsOneWidget);
    expect(find.textContaining('Tx #10 note'), findsOneWidget);
    expect(find.textContaining('Tx #9 note'), findsOneWidget);
    expect(find.textContaining('Tx #8 note'), findsOneWidget);

    // Transactions from later pages must NOT be present on Page 1
    expect(find.textContaining('Tx #7 note'), findsNothing);
    expect(find.textContaining('Tx #1 note'), findsNothing);

    // 2. Press Next to go to Page 2
    final nextBtnFinder = find.byKey(const Key('btn_tx_next'));
    expect(nextBtnFinder, findsOneWidget);
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();

    // Verify Page 2 displays items 6..10 (Tx #7 down to Tx #3)
    expect(find.text('Page 2 of 3 (12 items)'), findsOneWidget);
    expect(find.textContaining('Tx #7 note'), findsOneWidget);
    expect(find.textContaining('Tx #6 note'), findsOneWidget);
    expect(find.textContaining('Tx #5 note'), findsOneWidget);
    expect(find.textContaining('Tx #4 note'), findsOneWidget);
    expect(find.textContaining('Tx #3 note'), findsOneWidget);

    // Verify Page 1 items are NO LONGER present on Page 2 (fixes the bug where page 1 items repeated)
    expect(find.textContaining('Tx #12 note'), findsNothing);
    expect(find.textContaining('Tx #11 note'), findsNothing);
    expect(find.textContaining('Tx #10 note'), findsNothing);
    expect(find.textContaining('Tx #9 note'), findsNothing);
    expect(find.textContaining('Tx #8 note'), findsNothing);

    // 3. Press Next to go to Page 3
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();

    // Verify Page 3 displays remaining 2 items: Tx #2, Tx #1
    expect(find.text('Page 3 of 3 (12 items)'), findsOneWidget);
    expect(find.textContaining('Tx #2 note'), findsOneWidget);
    expect(find.textContaining('Tx #1 note'), findsOneWidget);
    expect(find.textContaining('Tx #3 note'), findsNothing);

    // 4. Press Prev to go back to Page 2
    final prevBtnFinder = find.byKey(const Key('btn_tx_prev'));
    expect(prevBtnFinder, findsOneWidget);
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 3 (12 items)'), findsOneWidget);
    expect(find.textContaining('Tx #7 note'), findsOneWidget);
    expect(find.textContaining('Tx #2 note'), findsNothing);

    // 5. Press Prev to go back to Page 1
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 3 (12 items)'), findsOneWidget);
    expect(find.textContaining('Tx #12 note'), findsOneWidget);

    // 6. Test toggling sort order (ascending: oldest first)
    final sortBtnFinder = find.byIcon(Icons.arrow_downward_rounded);
    expect(sortBtnFinder, findsOneWidget);
    await tester.tap(sortBtnFinder);
    await tester.pumpAndSettle();

    // When ascending, Page 1 must show Tx #1, Tx #2, Tx #3, Tx #4, Tx #5
    expect(find.text('Page 1 of 3 (12 items)'), findsOneWidget);
    expect(find.textContaining('Tx #1 note'), findsOneWidget);
    expect(find.textContaining('Tx #2 note'), findsOneWidget);
    expect(find.textContaining('Tx #3 note'), findsOneWidget);
    expect(find.textContaining('Tx #4 note'), findsOneWidget);
    expect(find.textContaining('Tx #5 note'), findsOneWidget);
    expect(find.textContaining('Tx #12 note'), findsNothing);
  });
}
