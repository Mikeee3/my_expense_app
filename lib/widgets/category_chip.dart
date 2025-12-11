import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onSelected;
  final bool showIcon;
  final bool showAmount;
  final double? amount;

  CategoryChip({
    required this.category,
    this.isSelected = false,
    required this.onSelected,
    this.showIcon = true,
    this.showAmount = false,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Text(AppConstants.categoryIcons[category] ?? '📝'),
            SizedBox(width: 4),
          ],
          Text(category),
          if (showAmount && amount != null) ...[
            SizedBox(width: 4),
            Text(
              '(\$${amount!.toStringAsFixed(2)})',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: _getCategoryColor(category).withOpacity(0.1),
      selectedColor: _getCategoryColor(category).withOpacity(0.3),
      checkmarkColor: _getCategoryColor(category),
      labelStyle: TextStyle(
        color: isSelected ? _getCategoryColor(category) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _getCategoryColor(category) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food & Dining': Colors.redAccent,
      'Transportation': Colors.blueAccent,
      'Shopping': Colors.greenAccent,
      'Bills & Utilities': Colors.orangeAccent,
      'Entertainment': Colors.purpleAccent,
      'Healthcare': Colors.pinkAccent,
      'Education': Colors.tealAccent,
      'Personal Care': Colors.deepOrangeAccent,
      'Travel': Colors.lightBlueAccent,
      'Gifts & Donations': Colors.lightGreenAccent,
      'Other': Colors.grey,
    };

    return colors[category] ?? Colors.grey;
  }
}
