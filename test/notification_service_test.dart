import 'package:flutter_test/flutter_test.dart';
import 'package:perfinax/controllers/data_controller.dart';
import 'package:perfinax/models/reminder_item.dart';
import 'package:perfinax/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Dual-Alert Logic Tests', () {
    test('Calculates 1-day-before and same-day trigger times at 09:00 AM accurately', () {
      final service = NotificationService.instance;
      final reminderDate = DateTime(2026, 10, 15, 14, 30); // 2:30 PM

      final dayBefore = service.getDayBeforeTriggerTime(reminderDate);
      expect(dayBefore.year, 2026);
      expect(dayBefore.month, 10);
      expect(dayBefore.day, 14);
      expect(dayBefore.hour, 9);
      expect(dayBefore.minute, 0);
      expect(dayBefore.second, 0);

      final sameDay = service.getSameDayTriggerTime(reminderDate);
      expect(sameDay.year, 2026);
      expect(sameDay.month, 10);
      expect(sameDay.day, 15);
      expect(sameDay.hour, 9);
      expect(sameDay.minute, 0);
      expect(sameDay.second, 0);
    });

    test('Generates deterministic, non-colliding 32-bit positive notification IDs', () {
      final service = NotificationService.instance;
      const reminderIdA = 'rem_1700000001000';
      const reminderIdB = 'rem_1700000002000';

      final alert1A = service.getDayBeforeNotificationId(reminderIdA);
      final alert2A = service.getSameDayNotificationId(reminderIdA);

      // Verify positive 32-bit integer
      expect(alert1A, isNonNegative);
      expect(alert2A, isNonNegative);
      expect(alert1A, lessThan(0x7FFFFFFF));
      expect(alert2A, lessThan(0x7FFFFFFF));

      // Verify dual alerts for the same reminder have different IDs
      expect(alert1A, isNot(equals(alert2A)));

      // Verify deterministic
      expect(service.getDayBeforeNotificationId(reminderIdA), equals(alert1A));
      expect(service.getSameDayNotificationId(reminderIdA), equals(alert2A));

      // Verify different reminders get different IDs
      final alert1B = service.getDayBeforeNotificationId(reminderIdB);
      expect(alert1A, isNot(equals(alert1B)));
    });

    test('DataController addReminder and removeReminder trigger notification service safely', () async {
      final controller = DataController();
      final reminder = ReminderItem(
        id: '12345',
        title: 'Electricity Bill',
        amount: 2500.0,
        type: 'expense',
        date: DateTime(2026, 11, 20),
      );

      // Adding reminder
      controller.addReminder(reminder);
      expect(controller.reminders.length, 1);
      expect(controller.reminders.first.title, 'Electricity Bill');

      // Removing reminder
      controller.removeReminder('12345');
      expect(controller.reminders.isEmpty, true);
    });
  });
}
