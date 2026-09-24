import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/reminder_item.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static const String channelId = 'perfinax_reminders';
  static const String channelName = 'Bill & Upcoming Reminders';
  static const String channelDescription =
      'Alerts for upcoming expense and bill reminders 1 day before and on due date';

  /// Initialize local notification plugin, permissions and timezone
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Initialize time zones
      tz_data.initializeTimeZones();
      try {
        final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (e) {
        debugPrint('NotificationService: Could not detect local timezone, falling back to local: $e');
      }

      // 2. Platform initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // 3. Request permissions explicitly for Android 13+ (API 33+)
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
      }

      final iosPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _initialized = true;
      debugPrint('NotificationService: Successfully initialized');
    } catch (e) {
      debugPrint('NotificationService: Initialization error (safe in tests/unsupported platforms): $e');
    }
  }

  /// Derive deterministic 32-bit positive notification IDs from reminder id
  int getDayBeforeNotificationId(String reminderId) {
    final baseId = reminderId.hashCode & 0x3FFFFFFF;
    return baseId * 2;
  }

  int getSameDayNotificationId(String reminderId) {
    final baseId = reminderId.hashCode & 0x3FFFFFFF;
    return baseId * 2 + 1;
  }

  /// Calculate the trigger time for 1 day before at custom or default 09:00 AM
  DateTime getDayBeforeTriggerTime(DateTime reminderDate,
      {int hour = 9, int minute = 0}) {
    return DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day - 1,
      hour,
      minute,
      0,
    );
  }

  /// Calculate the trigger time for the same day at custom or default 09:00 AM
  DateTime getSameDayTriggerTime(DateTime reminderDate,
      {int hour = 9, int minute = 0}) {
    return DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
      0,
    );
  }

  /// Parse time string like "09:00 AM", "2:30 PM", or "14:30" into hour and minute
  static ({int hour, int minute})? parseTimeString(String str) {
    try {
      final trimmed = str.trim();
      final isPm = trimmed.toLowerCase().contains('pm');
      final isAm = trimmed.toLowerCase().contains('am');
      final cleaned = trimmed.replaceAll(RegExp(r'[^\d:]'), '');
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        int h = int.tryParse(parts[0]) ?? 9;
        int m = int.tryParse(parts[1]) ?? 0;
        if (isPm && h < 12) h += 12;
        if (isAm && h == 12) h = 0;
        return (hour: h, minute: m);
      }
    } catch (_) {}
    return null;
  }

  /// Extract hour and minute configured for this reminder
  ({int hour, int minute}) getReminderAlarmTime(ReminderItem reminder) {
    if (reminder.time != null && reminder.time!.isNotEmpty) {
      final parsed = parseTimeString(reminder.time!);
      if (parsed != null) return parsed;
    }
    if (reminder.date.hour != 0 || reminder.date.minute != 0) {
      return (hour: reminder.date.hour, minute: reminder.date.minute);
    }
    return (hour: 9, minute: 0);
  }

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  void _ensureTimeZones() {
    try {
      tz.local;
    } catch (_) {
      tz_data.initializeTimeZones();
    }
  }

  /// Schedule both 1-day-before alert and same-day alert at user-chosen alarm time
  Future<void> scheduleDualAlerts(ReminderItem reminder) async {
    try {
      _ensureTimeZones();
      final now = DateTime.now();
      final alarmTime = getReminderAlarmTime(reminder);
      final dayBeforeTime = getDayBeforeTriggerTime(
        reminder.date,
        hour: alarmTime.hour,
        minute: alarmTime.minute,
      );
      final sameDayTime = getSameDayTriggerTime(
        reminder.date,
        hour: alarmTime.hour,
        minute: alarmTime.minute,
      );

      final dayBeforeId = getDayBeforeNotificationId(reminder.id);
      final sameDayId = getSameDayNotificationId(reminder.id);

      final amountStr =
          reminder.amount > 0 ? ' (৳${_formatAmount(reminder.amount)})' : '';
      final timeStr = reminder.time ??
          '${alarmTime.hour.toString().padLeft(2, '0')}:${alarmTime.minute.toString().padLeft(2, '0')}';

      // Notification details configuration
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Reminder Alert',
        icon: '@mipmap/launcher_icon',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      // Alert 1: 1 Day Before
      if (dayBeforeTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          id: dayBeforeId,
          title: 'Upcoming Reminder Tomorrow: ${reminder.title}',
          body:
              'Due tomorrow$amountStr at $timeStr. Plan your transaction ahead.',
          scheduledDate: tz.TZDateTime.from(dayBeforeTime, tz.local),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'reminder:${reminder.id}:day_before',
        );
        debugPrint(
            'Scheduled Alert 1 (1-day-before) for "${reminder.title}" at $dayBeforeTime');
      }

      // Alert 2: Same Day
      if (sameDayTime.isAfter(now)) {
        await _notificationsPlugin.zonedSchedule(
          id: sameDayId,
          title: 'Reminder Due Today: ${reminder.title}',
          body:
              'Due today$amountStr at $timeStr! Don\'t forget to complete this transaction.',
          scheduledDate: tz.TZDateTime.from(sameDayTime, tz.local),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'reminder:${reminder.id}:same_day',
        );
        debugPrint(
            'Scheduled Alert 2 (same-day) for "${reminder.title}" at $sameDayTime');
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule dual alerts: $e');
    }
  }

  /// Cancel both 1-day-before and same-day notifications for a reminder
  Future<void> cancelDualAlerts(String reminderId) async {
    try {
      final dayBeforeId = getDayBeforeNotificationId(reminderId);
      final sameDayId = getSameDayNotificationId(reminderId);

      await _notificationsPlugin.cancel(id: dayBeforeId);
      await _notificationsPlugin.cancel(id: sameDayId);
      debugPrint('NotificationService: Cancelled alerts for reminder $reminderId');
    } catch (e) {
      debugPrint('NotificationService: Error cancelling alerts: $e');
    }
  }

  /// Resynchronize all reminders (e.g. on app launch or data import)
  Future<void> syncAllReminders(List<ReminderItem> reminders) async {
    try {
      for (final r in reminders) {
        await scheduleDualAlerts(r);
      }
      debugPrint('NotificationService: Synchronized ${reminders.length} reminders');
    } catch (e) {
      debugPrint('NotificationService: Error syncing reminders: $e');
    }
  }
}
