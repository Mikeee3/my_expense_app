import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class DailyExpensesScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final DateTime selectedDate;

  DailyExpensesScreen({
    required this.expenseService,
    required this.selectedDate,
  });

  @override
  _DailyExpensesScreenState createState() => _DailyExpensesScreenState();
}

class _DailyExpensesScreenState extends State<DailyExpensesScreen> {
  late DateTime _selectedDate;
  List<Expense> _dailyExpenses = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadDailyExpenses();
  }

  void _loadDailyExpenses() {
    _dailyExpenses = widget.expenseService.expenses.where((expense) {
      return expense.date.year == _selectedDate.year &&
          expense.date.month == _selectedDate.month &&
          expense.date.day == _selectedDate.day;
    }).toList();

    // Sort by time (latest first)
    _dailyExpenses.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadDailyExpenses();
      });
    }
  }

  void _navigateToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(Duration(days: 1));
      _loadDailyExpenses();
    });
  }

  void _navigateToNextDay() {
    final tomorrow = _selectedDate.add(Duration(days: 1));
    if (tomorrow.isBefore(DateTime.now().add(Duration(days: 1)))) {
      setState(() {
        _selectedDate = tomorrow;
        _loadDailyExpenses();
      });
    }
  }

  double _calculateDailyTotal() {
    return _dailyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> _calculateCategoryTotals() {
    final Map<String, double> totals = {};

    for (var expense in _dailyExpenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final dailyTotal = _calculateDailyTotal();
    final categoryTotals = _calculateCategoryTotals();
    final isToday = Helpers.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Navigation
          Container(
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _navigateToPreviousDay,
                  ),
                  Column(
                    children: [
                      Text(
                        Helpers.getDayName(_selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        Helpers.formatDate(_selectedDate),
                        style: TextStyle(color: Colors.white70),
                      ),
                      if (isToday)
                        Chip(
                          label: Text('Today'),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: !isToday ? _navigateToNextDay : null,
                  ),
                ],
              ),
            ),
          ),

          // Daily Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Spent', style: TextStyle(fontSize: 18)),
                        Text(
                          '\$${dailyTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Number of Expenses',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '${_dailyExpenses.length} items',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Breakdown
          if (categoryTotals.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryTotals.entries.map((entry) {
                      final percentage = dailyTotal > 0
                          ? (entry.value / dailyTotal * 100)
                          : 0;

                      return Chip(
                        backgroundColor: Helpers.getCategoryColor(
                          entry.key,
                        ).withOpacity(0.2),
                        label: Text(
                          '${entry.key}: \$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                        ),
                        avatar: Text(
                          AppConstants.categoryIcons[entry.key] ?? '📝',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],

          // Expenses List
          Expanded(child: _buildExpensesList()),
        ],
      ),
    );
  }

  Widget _buildExpensesList() {
    if (_dailyExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No expenses on this day',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap + to add an expense',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _dailyExpenses.length,
      itemBuilder: (context, index) {
        final expense = _dailyExpenses[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Helpers.getCategoryColor(
                expense.category,
              ).withOpacity(0.2),
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
                  Helpers.formatTime(expense.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Expense Details'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailItem('Category', expense.category),
                        _buildDetailItem(
                          'Amount',
                          '\$${expense.amount.toStringAsFixed(2)}',
                        ),
                        _buildDetailItem(
                          'Date',
                          Helpers.formatDate(expense.date),
                        ),
                        _buildDetailItem(
                          'Time',
                          Helpers.formatTime(expense.date),
                        ),
                        if (expense.description.isNotEmpty)
                          _buildDetailItem('Description', expense.description),
                        _buildDetailItem(
                          'Added',
                          Helpers.getRelativeDate(expense.createdAt),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
