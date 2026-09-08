import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Transactions
      try {
        final txString = prefs.getString(_txKey);
        if (txString != null) {
          final List decoded = jsonDecode(txString);
          transactions =
              decoded.map((e) => TransactionItem.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('Error decoding transactions: $e');
      }

      // Load Reminders
      try {
        final remString = prefs.getString(_reminderKey);
        if (remString != null) {
          final List decoded = jsonDecode(remString);
          reminders = decoded.map((e) => ReminderItem.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('Error decoding reminders: $e');
      }

      // Load User Profile
      try {
        final userString = prefs.getString(_userKey);
        if (userString != null) {
          userProfile = UserProfile.fromJson(jsonDecode(userString));
        }
      } catch (e) {
        debugPrint('Error decoding user profile: $e');
      }
    } catch (e) {
      debugPrint('Error accessing SharedPreferences: $e');
    }
  }

  Future<void> saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(transactions.map((e) => e.toJson()).toList());
      await prefs.setString(_txKey, encoded);
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  Future<void> saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded =
          jsonEncode(reminders.map((e) => e.toJson()).toList());
      await prefs.setString(_reminderKey, encoded);
    } catch (e) {
      debugPrint('Error saving reminders: $e');
    }
  }

  Future<void> saveUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(userProfile.toJson());
      await prefs.setString(_userKey, encoded);
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
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
      final targetDay =
          tx.date.day > daysInNextMonth ? daysInNextMonth : tx.date.day;
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

  String exportBackupJson() {
    final Map<String, dynamic> data = {
      'version': 1,
      'app': 'PERFINAX',
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'userProfile': userProfile.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final dynamic decoded = jsonDecode(jsonString.trim());
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('transactions') &&
            decoded['transactions'] is List) {
          final List txList = decoded['transactions'];
          transactions =
              txList.map((e) => TransactionItem.fromJson(e)).toList();
        }

        if (decoded.containsKey('reminders') &&
            decoded['reminders'] is List) {
          final List remList = decoded['reminders'];
          reminders =
              remList.map((e) => ReminderItem.fromJson(e)).toList();
        }

        if (decoded.containsKey('userProfile') &&
            decoded['userProfile'] is Map) {
          userProfile = UserProfile.fromJson(
              Map<String, dynamic>.from(decoded['userProfile']));
        }
      } else if (decoded is List) {
        // Fallback if raw list of transactions was provided
        transactions =
            decoded.map((e) => TransactionItem.fromJson(e)).toList();
      }

      await saveTransactions();
      await saveReminders();
      await saveUserProfile();
      return true;
    } catch (e) {
      debugPrint('Error importing backup JSON: $e');
      return false;
    }
  }
}
