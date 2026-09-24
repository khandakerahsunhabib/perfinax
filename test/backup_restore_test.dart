import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/transaction_item.dart';
import 'package:perfinax/models/reminder_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('exportBackupJson generates valid JSON structure and importBackupJson restores it', () async {
    final controller = DataController();
    await controller.loadStorageData();

    final testTx = TransactionItem(
      id: 'tx_backup_1',
      type: 'income',
      amount: 5000.0,
      category: 'Salary',
      date: DateTime(2026, 9, 24),
      account: 'primary',
      note: 'Monthly salary',
      recurring: false,
    );

    final testReminder = ReminderItem(
      id: 'rem_backup_1',
      title: 'Utility Bill Payment',
      amount: 150.0,
      type: 'expense',
      date: DateTime(2026, 9, 25),
      time: '10:30 AM',
    );

    controller.addTransaction(testTx);
    controller.addReminder(testReminder);

    final exportedJson = controller.exportBackupJson();
    expect(exportedJson, isNotEmpty);

    final decoded = jsonDecode(exportedJson) as Map<String, dynamic>;
    expect(decoded['version'], equals(1));
    expect(decoded['app'], equals('PERFINAX'));
    expect(decoded['exportedAt'], isNotNull);
    expect(decoded['transactions'], isA<List>());
    expect((decoded['transactions'] as List).length, greaterThanOrEqualTo(1));
    expect(decoded['reminders'], isA<List>());
    expect((decoded['reminders'] as List).length, greaterThanOrEqualTo(1));

    // Create fresh controller and restore from exported JSON
    final restoredController = DataController();
    await restoredController.loadStorageData();
    final importSuccess = await restoredController.importBackupJson(exportedJson);

    expect(importSuccess, isTrue);
    expect(restoredController.transactions.any((tx) => tx.id == 'tx_backup_1'), isTrue);
    expect(restoredController.reminders.any((rem) => rem.id == 'rem_backup_1'), isTrue);
    final restoredRem = restoredController.reminders.firstWhere((rem) => rem.id == 'rem_backup_1');
    expect(restoredRem.time, equals('10:30 AM'));
  });
}
