class ReminderItem {
  final String id;
  final String title;
  final double amount;
  final String type; // 'expense', 'income'
  final DateTime date;
  final String? time; // e.g. '09:00 AM'

  ReminderItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type,
        'date': date.toIso8601String(),
        if (time != null) 'time': time,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        type: json['type'],
        date: DateTime.parse(json['date']),
        time: json['time'] as String?,
      );
}
