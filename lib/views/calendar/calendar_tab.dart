import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/data_controller.dart';
import '../../models/reminder_item.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a reminder title')));
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

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully!')));
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
                color: const Color(0xFF0A221C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SPENDING HEATMAP & REMINDERS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
                                  fontSize: 10,
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
                      childAspectRatio: 0.9),
                  itemCount: daysInMonth + firstDayOffset,
                  itemBuilder: (context, idx) {
                    if (idx < firstDayOffset) return const SizedBox();
                    final day = idx - firstDayOffset + 1;
                    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(
                        widget.selectedYear, widget.selectedMonth + 1, day));

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

                    Color bg = const Color(0xFF030A08);
                    if (expTotal > 0 && incTotal > 0) {
                      bg = const Color(0xFF064E3B);
                    } else if (expTotal > 0) {
                      bg = const Color(0xFF2A0D15);
                    } else if (incTotal > 0) {
                      bg = const Color(0xFF062018);
                    }

                    return Container(
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.2))),
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$day',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.slate400,
                                      fontWeight: FontWeight.bold)),
                              if (dayReminders.isNotEmpty)
                                const Text('🔔', style: TextStyle(fontSize: 8)),
                            ],
                          ),
                          Column(
                            children: [
                              if (incTotal > 0)
                                Text(
                                    '+${incTotal > 1000 ? '${(incTotal / 1000).toStringAsFixed(0)}k' : incTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 7,
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w900)),
                              if (expTotal > 0)
                                Text(
                                    '-${expTotal > 1000 ? '${(expTotal / 1000).toStringAsFixed(0)}k' : expTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 7,
                                        color: AppColors.rose400,
                                        fontWeight: FontWeight.w900)),
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
          const SizedBox(height: 16),

          // Reminder Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF0A221C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SET UPCOMING REMINDER',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981))),
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
                          fillColor: const Color(0xFF030A08),
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
                          fillColor: const Color(0xFF030A08),
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
                              color: const Color(0xFF030A08),
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
        ],
      ),
    );
  }
}
