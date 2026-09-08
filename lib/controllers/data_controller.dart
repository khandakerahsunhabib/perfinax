import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_item.dart';
import '../models/reminder_item.dart';
import '../models/user_profile.dart';

class DataController {
  List<TransactionItem> transactions = [];
  List<ReminderItem> reminders = [];
  UserProfile userProfile = UserProfile();

  static const String _txKey = 'pernance_phone_db';
  static const String _reminderKey = 'pernance_reminders';
  static const String _userKey = 'pernance_user_profile';

  Future<void> loadStorageData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Transactions
    final txString = prefs.getString(_txKey);
    if (txString != null) {
      final List decoded = jsonDecode(txString);
      transactions = decoded.map((e) => TransactionItem.fromJson(e)).toList();
    }

    // Load Reminders
    final remString = prefs.getString(_reminderKey);
    if (remString != null) {
      final List decoded = jsonDecode(remString);
      reminders = decoded.map((e) => ReminderItem.fromJson(e)).toList();
    }

    // Load User Profile
    final userString = prefs.getString(_userKey);
    if (userString != null) {
      userProfile = UserProfile.fromJson(jsonDecode(userString));
    }
  }

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_txKey, encoded);
  }

  Future<void> saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(reminders.map((e) => e.toJson()).toList());
    await prefs.setString(_reminderKey, encoded);
  }

  Future<void> saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(userProfile.toJson());
    await prefs.setString(_userKey, encoded);
  }

  void addTransaction(TransactionItem tx) {
    transactions.add(tx);
    if (tx.recurring) {
      int nextMonth = tx.date.month + 1;
      int nextYear = tx.date.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
      final targetDay = tx.date.day > daysInNextMonth ? daysInNextMonth : tx.date.day;
      final nextDate = DateTime(nextYear, nextMonth, targetDay);

      final nextTx = TransactionItem(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        type: tx.type,
        amount: tx.amount,
        category: tx.category,
        date: nextDate,
        account: tx.account,
        note: "${tx.note} (Scheduled Recurring)".trim(),
        recurring: true,
      );
      transactions.add(nextTx);
    }
    saveTransactions();
  }

  void removeTransaction(String id) {
    transactions.removeWhere((t) => t.id == id);
    saveTransactions();
  }

  void addReminder(ReminderItem reminder) {
    reminders.add(reminder);
    saveReminders();
  }

  void removeReminder(String id) {
    reminders.removeWhere((r) => r.id == id);
    saveReminders();
  }
}
