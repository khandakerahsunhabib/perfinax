import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/transaction_item.dart';
import 'package:perfinax/models/user_profile.dart';
import 'package:perfinax/views/calendar/calendar_tab.dart';

void main() {
  testWidgets('CalendarTab shows round figures as 2K/4K and non-round figures as exact amounts (550, 450, 1800)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dataController = DataController();
    dataController.userProfile = UserProfile(
      name: 'User',
      occupation: 'Dev',
      phone: '+8801700000000',
      address: 'Dhaka',
      primaryBank: 'Bank',
      secondaryBank: 'Sec',
      mfs: 'bKash',
    );

    // Selected month: October 2026 (selectedMonth = 9 -> month = 10)
    dataController.transactions = [
      // 1. Exact non-round figure 1800 on Oct 5 (should be -1800, NOT -2K)
      TransactionItem(
        id: '1',
        type: 'expense',
        amount: 1800.0,
        category: 'Food & Groceries',
        date: DateTime(2026, 10, 5),
        account: 'primary',
        note: 'Supermarket shopping',
        recurring: false,
      ),
      // 2. Solid round figure 2000 on Oct 10 (should be +2K)
      TransactionItem(
        id: '2',
        type: 'income',
        amount: 2000.0,
        category: 'Salary',
        date: DateTime(2026, 10, 10),
        account: 'primary',
        note: 'Freelance payment',
        recurring: false,
      ),
      // 3. Solid round figure 4000 on Oct 15 (should be -4K)
      TransactionItem(
        id: '3',
        type: 'expense',
        amount: 4000.0,
        category: 'Rent',
        date: DateTime(2026, 10, 15),
        account: 'primary',
        note: 'House rent',
        recurring: false,
      ),
      // 4. Non-round figure 550 on Oct 20 (should be +550)
      TransactionItem(
        id: '4',
        type: 'income',
        amount: 550.0,
        category: 'Other Income',
        date: DateTime(2026, 10, 20),
        account: 'primary',
        note: 'Interest received',
        recurring: false,
      ),
      // 5. Non-round figure 450 on Oct 25 (should be -450)
      TransactionItem(
        id: '5',
        type: 'expense',
        amount: 450.0,
        category: 'Transport',
        date: DateTime(2026, 10, 25),
        account: 'primary',
        note: 'Bus fare',
        recurring: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: CalendarTab(
            dataController: dataController,
            selectedYear: 2026,
            selectedMonth: 9, // October
            onDataChanged: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify exact amount '-1800' is displayed for 1800 (not -2K)
    expect(find.text('-1800'), findsOneWidget);

    // 2. Verify solid round figure 2000 displays as '+2K'
    expect(find.text('+2K'), findsOneWidget);

    // 3. Verify solid round figure 4000 displays as '-4K'
    expect(find.text('-4K'), findsOneWidget);

    // 4. Verify non-round figure 550 displays as exact '+550'
    expect(find.text('+550'), findsOneWidget);

    // 5. Verify non-round figure 450 displays as exact '-450'
    expect(find.text('-450'), findsOneWidget);

    // 6. Verify font size of amount text is enlarged (>= 9.0)
    final expenseText = tester.widget<Text>(find.text('-1800'));
    expect(expenseText.style?.fontSize, greaterThanOrEqualTo(9.0));

    final roundText = tester.widget<Text>(find.text('+2K'));
    expect(roundText.style?.fontSize, greaterThanOrEqualTo(9.0));
  });
}
