class TransactionItem {
  final String id;
  final String type; // 'expense', 'income', 'saving', 'transfer'
  final double amount;
  final String category;
  final DateTime date;
  final String account; // 'primary', 'secondary', 'mfs', 'cash'
  final String note;
  final bool recurring;

  TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.account,
    required this.note,
    required this.recurring,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'account': account,
        'note': note,
        'recurring': recurring,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'],
        type: json['type'],
        amount: (json['amount'] as num).toDouble(),
        category: json['category'],
        date: DateTime.parse(json['date']),
        account: json['account'],
        note: json['note'] ?? '',
        recurring: json['recurring'] ?? false,
      );
}
