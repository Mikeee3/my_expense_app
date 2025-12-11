import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../utils/constants.dart';

class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Color primaryColor;
  final Color lightGreen;
  final Color cardBg;

  const ExpenseListTile({
    Key? key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
    this.primaryColor = const Color(0xFF4CAF50),
    this.lightGreen = const Color(0xFFE8F5E9),
    this.cardBg = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category),
          child: Text(
            AppConstants.categoryIcons[expense.category] ?? '📝',
            style: TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          expense.category,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.description.isNotEmpty) Text(expense.description),
            Text(
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              '${expense.date.hour.toString().padLeft(2, '0')}:${expense.date.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Expense Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: ${expense.category}'),
                  Text('Amount: \$${expense.amount.toStringAsFixed(2)}'),
                  Text('Date: ${expense.date.toString().split(' ')[0]}'),
                  if (expense.description.isNotEmpty)
                    Text('Description: ${expense.description}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  child: Text('Edit'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
    ];

    final index = AppConstants.categories.indexOf(category);
    return index != -1
        ? colors[index % colors.length].withOpacity(0.2)
        : Colors.grey[200]!;
  }
}
