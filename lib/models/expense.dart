class Expense {
  String id;
  double amount;
  String category;
  DateTime date;
  String description;
  DateTime createdAt;

  Expense({
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
    String? id,
    DateTime? createdAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
