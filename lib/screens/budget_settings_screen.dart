import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import '../utils/validators.dart';

class BudgetSettingsScreen extends StatefulWidget {
  final ExpenseService expenseService;
  final VoidCallback onBudgetUpdated;

  BudgetSettingsScreen({
    required this.expenseService,
    required this.onBudgetUpdated,
  });

  @override
  _BudgetSettingsScreenState createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final _dailyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();
  final _dailyBudgetFormKey = GlobalKey<FormState>();
  final _monthlyBudgetFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCurrentBudgets();
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  void _loadCurrentBudgets() {
    final dailyBudget = widget.expenseService.settings['dailyBudget'] ?? 50.0;
    final monthlyBudget =
        widget.expenseService.settings['monthlyBudget'] ?? 1500.0;

    _dailyBudgetController.text = dailyBudget.toStringAsFixed(2);
    _monthlyBudgetController.text = monthlyBudget.toStringAsFixed(2);
  }

  Future<void> _updateDailyBudget() async {
    if (_dailyBudgetFormKey.currentState!.validate()) {
      final amount = double.parse(_dailyBudgetController.text);
      await widget.expenseService.setDailyBudget(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Daily budget updated to \$${amount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onBudgetUpdated();
      setState(() {});
    }
  }

  Future<void> _updateMonthlyBudget() async {
    if (_monthlyBudgetFormKey.currentState!.validate()) {
      final amount = double.parse(_monthlyBudgetController.text);
      await widget.expenseService.setMonthlyBudget(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Monthly budget updated to \$${amount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      widget.onBudgetUpdated();
      setState(() {});
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Budgets'),
        content: Text(
          'Reset daily budget to \$50 and monthly budget to \$1500?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await widget.expenseService.setDailyBudget(50.0);
              await widget.expenseService.setMonthlyBudget(1500.0);

              _loadCurrentBudgets();
              widget.onBudgetUpdated();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Budgets reset to defaults'),
                  backgroundColor: Colors.blue,
                ),
              );

              setState(() {});
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showBudgetTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Budget Tips'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipItem('💰', 'Set realistic budgets based on your income'),
              _buildTipItem('📊', 'Track your spending for 1-2 weeks first'),
              _buildTipItem('🎯', 'Aim to save 20% of your income'),
              _buildTipItem(
                '🛒',
                'Allocate 50% for needs, 30% for wants, 20% for savings',
              ),
              _buildTipItem(
                '📈',
                'Adjust budgets monthly based on actual spending',
              ),
              _buildTipItem(
                '🔔',
                'Set alerts when you reach 80% of your budget',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyBudget = widget.expenseService.settings['dailyBudget'] ?? 50.0;
    final monthlyBudget =
        widget.expenseService.settings['monthlyBudget'] ?? 1500.0;
    final dailySpent = widget.expenseService.getTodayTotal();
    final monthlySpent = widget.expenseService.getMonthlyTotal();
    final dailyRemaining = dailyBudget - dailySpent;
    final monthlyRemaining = monthlyBudget - monthlySpent;

    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showBudgetTips,
            tooltip: 'Budget Tips',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Current Budget Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Budget Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildBudgetStatusItem(
                    'Daily',
                    dailyBudget,
                    dailySpent,
                    dailyRemaining,
                    Colors.green,
                  ),
                  SizedBox(height: 12),
                  _buildBudgetStatusItem(
                    'Monthly',
                    monthlyBudget,
                    monthlySpent,
                    monthlyRemaining,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Daily Budget Editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _dailyBudgetFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _dailyBudgetController,
                      decoration: InputDecoration(
                        labelText: 'Daily Budget Amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.today),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.validateBudget,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateDailyBudget,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Update Daily Budget'),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tips: Set a daily limit that covers your regular expenses',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Monthly Budget Editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _monthlyBudgetFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _monthlyBudgetController,
                      decoration: InputDecoration(
                        labelText: 'Monthly Budget Amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.validateBudget,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateMonthlyBudget,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Update Monthly Budget'),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tips: Your monthly budget should be about 30x your daily budget',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Quick Presets
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Presets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('Student', 30, 900),
                      _buildPresetChip('Standard', 50, 1500),
                      _buildPresetChip('Premium', 100, 3000),
                      _buildPresetChip('Saver', 25, 750),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Reset Button
          OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.red),
            ),
            child: Text(
              'Reset to Defaults',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatusItem(
    String label,
    double budget,
    double spent,
    double remaining,
    Color color,
  ) {
    final double percentage = budget > 0 ? spent / budget : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label Budget',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${budget.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: \$${spent.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              'Remaining: \$${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                color: remaining >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 1),
            minHeight: 6,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 0.9 ? Colors.red : color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}% used',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, double daily, double monthly) {
    return FilterChip(
      label: Text('$label: \$$daily/\$$monthly'),
      onSelected: (_) async {
        await widget.expenseService.setDailyBudget(daily);
        await widget.expenseService.setMonthlyBudget(monthly);

        _loadCurrentBudgets();
        widget.onBudgetUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied $label preset'),
            backgroundColor: Colors.blue,
          ),
        );

        setState(() {});
      },
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
    );
  }
}
