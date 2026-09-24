import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/data_controller.dart';
import '../../models/reminder_item.dart';
import '../../models/transaction_item.dart';
import '../widgets/app_toast.dart';

class CalendarTab extends StatefulWidget {
  final DataController dataController;
  final int selectedYear;
  final int selectedMonth;
  final VoidCallback onDataChanged;

  const CalendarTab({
    super.key,
    required this.dataController,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onDataChanged,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  final TextEditingController _reminderTitleController = TextEditingController();
  final TextEditingController _reminderAmountController = TextEditingController();
  DateTime _reminderDate = DateTime.now();

  @override
  void dispose() {
    _reminderTitleController.dispose();
    _reminderAmountController.dispose();
    super.dispose();
  }

  void _addReminder() {
    if (_reminderTitleController.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'Please enter a reminder title',
        type: ToastType.error,
      );
      return;
    }

    final double amount =
        double.tryParse(_reminderAmountController.text.trim()) ?? 0.0;

    final reminder = ReminderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _reminderTitleController.text.trim(),
      amount: amount,
      type: 'expense',
      date: _reminderDate,
    );

    widget.dataController.addReminder(reminder);
    widget.onDataChanged();

    _reminderTitleController.clear();
    _reminderAmountController.clear();

    AppToast.show(
      context,
      message: 'Reminder added successfully!',
      type: ToastType.success,
    );
  }

  void _confirmDeleteReminder(ReminderItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.rose400.withValues(alpha: 0.3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.rose400, size: 22),
              SizedBox(width: 8),
              Text(
                'Delete Reminder?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete '${item.title}'?\nThis action cannot be undone.",
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: const BorderSide(color: AppColors.slate500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('CANCEL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.dataController.removeReminder(item.id);
                widget.onDataChanged();
                setState(() {});
                AppToast.show(
                  context,
                  message: 'Reminder deleted',
                  type: ToastType.delete,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('DELETE',
                  style:
                      TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount % 1 == 0) {
      return amount.toInt().toString();
    }
    final fixed = amount.toStringAsFixed(2);
    if (fixed.endsWith('.00')) {
      return amount.toInt().toString();
    }
    if (fixed.endsWith('0')) {
      return amount.toStringAsFixed(1);
    }
    return fixed;
  }

  String _formatCalendarAmount(double amount) {
    // Solid round figures like 1000, 2000, 4000 show as 1K, 2K, 4K
    if (amount >= 1000 && amount % 1000 == 0) {
      return '${(amount / 1000).toInt()}K';
    }
    // Non-round figures (e.g. 450, 550, 1800) show exact amount
    return _formatAmount(amount);
  }

  void _showDayDetails({
    required BuildContext context,
    required DateTime date,
    required List<TransactionItem> dayExpenses,
    required List<TransactionItem> dayIncomes,
    required List<ReminderItem> dayReminders,
  }) {
    final dateStr = DateFormat('MMMM d, yyyy').format(date);
    final totalInc = dayIncomes.fold(0.0, (s, t) => s + t.amount);
    final totalExp = dayExpenses.fold(0.0, (s, t) => s + t.amount);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slate500.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (totalInc > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+৳${_formatAmount(totalInc)}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (totalExp > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.rose.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-৳${_formatAmount(totalExp)}',
                              style: const TextStyle(
                                color: AppColors.rose400,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (dayIncomes.isEmpty &&
                    dayExpenses.isEmpty &&
                    dayReminders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No transactions or reminders on this date.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.slate400),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (dayIncomes.isNotEmpty) ...[
                          const Text('INCOME',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          ...dayIncomes.map((t) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.emerald
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(t.category,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11)),
                                          if (t.note.isNotEmpty)
                                            Text(t.note,
                                                style: const TextStyle(
                                                    fontSize: 9,
                                                    color: AppColors.slate400)),
                                        ],
                                      ),
                                    ),
                                    Text('+৳${_formatAmount(t.amount)}',
                                        style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 8),
                        ],
                        if (dayExpenses.isNotEmpty) ...[
                          const Text('EXPENSES',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.rose400,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          ...dayExpenses.map((t) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.rose
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(t.category,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11)),
                                          if (t.note.isNotEmpty)
                                            Text(t.note,
                                                style: const TextStyle(
                                                    fontSize: 9,
                                                    color: AppColors.slate400)),
                                        ],
                                      ),
                                    ),
                                    Text('-৳${_formatAmount(t.amount)}',
                                        style: const TextStyle(
                                            color: AppColors.rose400,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 8),
                        ],
                        if (dayReminders.isNotEmpty) ...[
                          const Text('REMINDERS',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sky400,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          ...dayReminders.map((r) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.sky400
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(r.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                    if (r.amount > 0)
                                      Text('৳${_formatAmount(r.amount)}',
                                          style: const TextStyle(
                                              color: AppColors.rose400,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(widget.selectedYear, widget.selectedMonth + 1, 0).day;
    final firstDayOffset =
        DateTime(widget.selectedYear, widget.selectedMonth + 1, 1).weekday % 7;

    final transactions = widget.dataController.transactions;
    final reminders = widget.dataController.reminders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPENDING HEATMAP & REMINDERS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Text('Green = Income',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold)),
                    Text(' | ',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.slate500)),
                    Text('Red = Expense',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.rose400,
                            fontWeight: FontWeight.bold)),
                    Text(' | 🔔 = Reminder',
                        style:
                            TextStyle(fontSize: 10, color: AppColors.slate400)),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid Days Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map((d) => SizedBox(
                          width: 36,
                          child: Text(d,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate400,
                                  fontWeight: FontWeight.bold))))
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Grid Days Matrix
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 0.78),
                  itemCount: daysInMonth + firstDayOffset,
                  itemBuilder: (context, idx) {
                    if (idx < firstDayOffset) return const SizedBox();
                    final day = idx - firstDayOffset + 1;
                    final dayDate = DateTime(
                        widget.selectedYear, widget.selectedMonth + 1, day);
                    final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);

                    final dayExpenses = transactions
                        .where((t) =>
                            DateFormat('yyyy-MM-dd').format(t.date) == dateStr &&
                            t.type == 'expense')
                        .toList();
                    final dayIncomes = transactions
                        .where((t) =>
                            DateFormat('yyyy-MM-dd').format(t.date) == dateStr &&
                            (t.type == 'income' ||
                                t.category == 'Cash Received'))
                        .toList();
                    final dayReminders = reminders
                        .where((r) =>
                            DateFormat('yyyy-MM-dd').format(r.date) == dateStr)
                        .toList();

                    final expTotal =
                        dayExpenses.fold(0.0, (s, t) => s + t.amount);
                    final incTotal =
                        dayIncomes.fold(0.0, (s, t) => s + t.amount);

                    Color bg = Theme.of(context).scaffoldBackgroundColor;
                    if (expTotal > 0 && incTotal > 0) {
                      bg = const Color(0xFF064E3B);
                    } else if (expTotal > 0) {
                      bg = const Color(0xFF2A0D15);
                    } else if (incTotal > 0) {
                      bg = const Color(0xFF062018);
                    }

                    final hasActivity = incTotal > 0 || expTotal > 0;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _showDayDetails(
                          context: context,
                          date: dayDate,
                          dayExpenses: dayExpenses,
                          dayIncomes: dayIncomes,
                          dayReminders: dayReminders,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: (incTotal > 0 && expTotal > 0)
                                    ? AppColors.emerald.withValues(alpha: 0.45)
                                    : incTotal > 0
                                        ? AppColors.emerald.withValues(alpha: 0.35)
                                        : expTotal > 0
                                            ? AppColors.rose400.withValues(alpha: 0.35)
                                            : AppColors.emerald.withValues(alpha: 0.15),
                                width: hasActivity ? 1.0 : 0.8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 3.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$day',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        color: hasActivity
                                            ? Theme.of(context).colorScheme.onSurface
                                            : AppColors.slate400,
                                        fontWeight: FontWeight.bold)),
                                if (dayReminders.isNotEmpty)
                                  const Text('🔔',
                                      style: TextStyle(fontSize: 9.5)),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (incTotal > 0)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                        '+${_formatCalendarAmount(incTotal)}',
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.2)),
                                  ),
                                if (expTotal > 0)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                        '-${_formatCalendarAmount(expTotal)}',
                                        style: const TextStyle(
                                            fontSize: 9.5,
                                            color: AppColors.rose400,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.2)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reminder Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SET UPCOMING REMINDER',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_active_outlined,
                              size: 11, color: Color(0xFF34D399)),
                          SizedBox(width: 4),
                          Text('Dual Alerts (1-Day Before & Due Day)',
                              style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34D399))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _reminderTitleController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Title (e.g. Rent)',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _reminderAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Amount',
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context,
                              initialDate: _reminderDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030));
                          if (d != null) setState(() => _reminderDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              DateFormat('yyyy-MM-dd').format(_reminderDate),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('ADD REMINDER',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. UPCOMING REMINDERS RECORD CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPCOMING REMINDERS RECORD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                if (reminders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Text(
                        'No upcoming reminders recorded.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.slate400
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reminders.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final item = reminders[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.emerald.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Due: ${DateFormat('yyyy-MM-dd').format(item.date)}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (item.amount > 0) ...[
                                  Text(
                                    '৳${item.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: AppColors.rose400,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.slate500),
                                  onPressed: () => _confirmDeleteReminder(item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
