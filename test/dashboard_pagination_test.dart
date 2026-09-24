import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/transaction_item.dart';
import 'package:perfinax/models/user_profile.dart';
import 'package:perfinax/views/dashboard/dashboard_tab.dart';

void main() {
  testWidgets('DashboardTab Latest Transactions pagination works sequentially and accurately',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
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

    // Create 22 transactions in October 2026 (selectedMonth = 9 -> month 10)
    // With 10-per-page: Page 1 = Tx#22..Tx#13, Page 2 = Tx#12..Tx#3, Page 3 = Tx#2..Tx#1
    final List<TransactionItem> testItems = [];
    for (int i = 1; i <= 22; i++) {
      testItems.add(
        TransactionItem(
          id: '100$i',
          type: i % 2 == 0 ? 'income' : 'expense',
          amount: (i * 100).toDouble(),
          category: i % 2 == 0 ? 'Salary' : 'Food & Groceries',
          date: DateTime(2026, 10, (i % 28) + 1),
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

    // Page 1: 10 items per page, descending by date
    expect(find.text('Page 1 of 3 (22 items)'), findsOneWidget);
    // First few items visible on page 1
    expect(find.textContaining('Tx #22 note'), findsOneWidget);
    expect(find.textContaining('Tx #21 note'), findsOneWidget);

    // Items on later pages must NOT appear on page 1
    expect(find.textContaining('Tx #1 note'), findsNothing);
    expect(find.textContaining('Tx #2 note'), findsNothing);

    // 2. Press Next to go to Page 2
    final nextBtnFinder = find.byKey(const Key('btn_tx_next'));
    expect(nextBtnFinder, findsOneWidget);
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 3 (22 items)'), findsOneWidget);
    // Page 1 items must NOT appear on page 2
    expect(find.textContaining('Tx #22 note'), findsNothing);
    expect(find.textContaining('Tx #21 note'), findsNothing);

    // 3. Press Next to go to Page 3
    await tester.tap(nextBtnFinder);
    await tester.pumpAndSettle();

    // Page 3 has the 2 remaining items: Tx#2 and Tx#1
    expect(find.text('Page 3 of 3 (22 items)'), findsOneWidget);
    expect(find.textContaining('Tx #2 note'), findsOneWidget);
    expect(find.textContaining('Tx #1 note'), findsOneWidget);

    // 4. Press Prev to go back to Page 2
    final prevBtnFinder = find.byKey(const Key('btn_tx_prev'));
    expect(prevBtnFinder, findsOneWidget);
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 3 (22 items)'), findsOneWidget);
    expect(find.textContaining('Tx #1 note'), findsNothing);

    // 5. Press Prev to go back to Page 1
    await tester.tap(prevBtnFinder);
    await tester.pumpAndSettle();

    expect(find.text('Page 1 of 3 (22 items)'), findsOneWidget);
    expect(find.textContaining('Tx #22 note'), findsOneWidget);

    // 6. Test toggling sort order (ascending: oldest first)
    final sortBtnFinder = find.byIcon(Icons.arrow_downward_rounded);
    expect(sortBtnFinder, findsOneWidget);
    await tester.tap(sortBtnFinder);
    await tester.pumpAndSettle();

    // Ascending: Page 1 must show the earliest 10 items
    expect(find.text('Page 1 of 3 (22 items)'), findsOneWidget);
    expect(find.textContaining('Tx #1 note'), findsOneWidget);
    expect(find.textContaining('Tx #2 note'), findsOneWidget);
    expect(find.textContaining('Tx #22 note'), findsNothing);
  });
}
