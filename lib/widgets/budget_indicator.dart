import 'package:flutter/material.dart';

class BudgetIndicator extends StatelessWidget {
  final double dailyRemaining;
  final double monthlyRemaining;
  final double dailyBudget;
  final double monthlyBudget;
  final VoidCallback? onBudgetTap;
  final Color primaryColor;
  final Color lightGreen;

  const BudgetIndicator({
    Key? key,
    required this.dailyRemaining,
    required this.monthlyRemaining,
    required this.dailyBudget,
    required this.monthlyBudget,
    this.onBudgetTap,
    this.primaryColor = const Color(0xFF4CAF50),
    this.lightGreen = const Color(0xFFE8F5E9),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dailySpent = dailyBudget - dailyRemaining;
    final monthlySpent = monthlyBudget - monthlyRemaining;
    final double dailyPercentage = dailyBudget > 0
        ? dailySpent / dailyBudget
        : 0;
    final double monthlyPercentage = monthlyBudget > 0
        ? monthlySpent / monthlyBudget
        : 0;

    return InkWell(
      onTap: onBudgetTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBudgetItem(
              context,
              'Daily Budget',
              dailyBudget,
              dailySpent,
              dailyRemaining,
              dailyPercentage,
              Colors.greenAccent,
            ),
            SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.3), height: 1),
            SizedBox(height: 16),
            _buildBudgetItem(
              context,
              'Monthly Budget',
              monthlyBudget,
              monthlySpent,
              monthlyRemaining,
              monthlyPercentage,
              Colors.blueAccent,
            ),
            SizedBox(height: 8),
            _buildBudgetStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(
    BuildContext context,
    String label,
    double budget,
    double spent,
    double remaining,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Icon(
                  _getBudgetIcon(remaining),
                  color: remaining >= 0 ? Colors.white : Colors.red[200],
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  remaining >= 0 ? 'On track' : 'Over budget',
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.white : Colors.red[200],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${spent.toStringAsFixed(2)} spent',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '\$${remaining.toStringAsFixed(2)} remaining',
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.white : Colors.red[200],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Chip(
              backgroundColor: Colors.white.withOpacity(0.2),
              label: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1),
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.9 ? Colors.red : color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              '\$${budget.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetStatus() {
    if (dailyRemaining < 0 && monthlyRemaining < 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.red[200], size: 16),
          SizedBox(width: 4),
          Text(
            'Over both daily & monthly budget',
            style: TextStyle(color: Colors.red[200], fontSize: 12),
          ),
        ],
      );
    } else if (dailyRemaining < 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.red[200], size: 16),
          SizedBox(width: 4),
          Text(
            'Over daily budget',
            style: TextStyle(color: Colors.red[200], fontSize: 12),
          ),
        ],
      );
    } else if (monthlyRemaining < 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.red[200], size: 16),
          SizedBox(width: 4),
          Text(
            'Over monthly budget',
            style: TextStyle(color: Colors.red[200], fontSize: 12),
          ),
        ],
      );
    } else if (dailyRemaining < dailyBudget * 0.2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info, color: Colors.orange[200], size: 16),
          SizedBox(width: 4),
          Text(
            'Daily budget almost exhausted',
            style: TextStyle(color: Colors.orange[200], fontSize: 12),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green[200], size: 16),
          SizedBox(width: 4),
          Text(
            'Within budget limits',
            style: TextStyle(color: Colors.green[200], fontSize: 12),
          ),
        ],
      );
    }
  }

  IconData _getBudgetIcon(double remaining) {
    if (remaining < 0) return Icons.warning;
    if (remaining < 10) return Icons.info;
    return Icons.check_circle;
  }
}
