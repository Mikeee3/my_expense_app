import 'package:flutter/material.dart';
import 'package:my_expense_app/models/expense.dart';
import 'package:my_expense_app/screens/daily_expenses_screen.dart';
import 'package:my_expense_app/screens/data_management_screen.dart';
import 'package:my_expense_app/screens/edit_expense_screen.dart';
import '../services/expense_service.dart';
import '../widgets/expense_list_tile.dart';
import 'add_expense_screen.dart';
import 'reports_screen.dart';
import 'budget_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _expenseService.loadData();
    setState(() {});
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(
          expense: expense,
          expenseService: _expenseService,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayExpenses = _expenseService.getTodayExpenses();
    final todayTotal = _expenseService.getTodayTotal();
    final dailyBudget = _expenseService.settings['dailyBudget'] ?? 50.0;
    final monthlyBudget = _expenseService.settings['monthlyBudget'] ?? 1500.0;
    final dailySpent = _expenseService.getTodayTotal();
    final monthlySpent = _expenseService.getMonthlyTotal();
    final dailyRemaining = dailyBudget - dailySpent;
    final monthlyRemaining = monthlyBudget - monthlySpent;
    final double dailyPercentage = dailyBudget > 0 ? dailySpent / dailyBudget : 0;
    final double monthlyPercentage = monthlyBudget > 0
        ? monthlySpent / monthlyBudget
        : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepPurple,
        elevation: 0,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReportsScreen(expenseService: _expenseService),
                ),
              );
            },
            tooltip: 'Reports',
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetSettingsScreen(
                    expenseService: _expenseService,
                    onBudgetUpdated: () => setState(() {}),
                  ),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick Stats Cards
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Today',
                      amount: todayTotal,
                      icon: Icons.today_outlined,
                      color: Colors.deepPurple,
                      isMoney: true,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Daily Left',
                      amount: dailyRemaining,
                      icon: Icons.account_balance_wallet_outlined,
                      color: dailyRemaining >= 0 ? Colors.green : Colors.orange,
                      isMoney: true,
                      showTrend: dailyRemaining >= 0,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Expenses',
                      amount: todayExpenses.length.toDouble(),
                      icon: Icons.receipt_long_outlined,
                      color: Colors.blue,
                      isMoney: false,
                    ),
                  ),
                ],
              ),
            ),

            // Budget Progress Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.more_horiz,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BudgetSettingsScreen(
                                    expenseService: _expenseService,
                                    onBudgetUpdated: () => setState(() {}),
                                  ),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildBudgetProgress(
                        label: 'Daily Budget',
                        spent: dailySpent,
                        total: dailyBudget,
                        remaining: dailyRemaining,
                        percentage: dailyPercentage,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(height: 20),
                      _buildBudgetProgress(
                        label: 'Monthly Budget',
                        spent: monthlySpent,
                        total: monthlyBudget,
                        remaining: monthlyRemaining,
                        percentage: monthlyPercentage,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Recent Expenses Header with Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.today_outlined,
                              color: Colors.deepPurple,
                              size: 22,
                            ),
                            onPressed: _viewTodayExpenses,
                            tooltip: 'View Today\'s Expenses',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.storage_outlined,
                              color: Colors.deepPurple,
                              size: 22,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DataManagementScreen(
                                    expenseService: _expenseService,
                                  ),
                                ),
                              );
                            },
                            tooltip: 'Data Management',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.deepPurple,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Expenses List
            Expanded(child: _buildExpensesList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddExpenseScreen(expenseService: _expenseService),
            ),
          );
          setState(() {});
        },
        child: Icon(Icons.add, size: 28),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isMoney,
    bool showTrend = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (showTrend)
                Icon(Icons.trending_up, size: 16, color: Colors.green),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            isMoney
                ? '\$${amount.toStringAsFixed(2)}'
                : amount.toInt().toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress({
    required String label,
    required double spent,
    required double total,
    required double remaining,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '\$${spent.toStringAsFixed(2)} / \$${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width:
                  MediaQuery.of(context).size.width *
                  0.7 *
                  percentage.clamp(0, 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(percentage * 100).toStringAsFixed(0)}% used',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '\$${remaining.toStringAsFixed(2)} left',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: remaining >= 0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensesList() {
    List<Expense> displayExpenses;

    if (_searchQuery.isNotEmpty) {
      displayExpenses = _expenseService.searchExpenses(_searchQuery);
    } else {
      displayExpenses = _expenseService.getTodayExpenses();
    }

    if (displayExpenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No expenses found'
                  : 'No expenses today',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            if (!_searchQuery.isNotEmpty)
              Text(
                'Tap + to add your first expense',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: displayExpenses.length,
      itemBuilder: (context, index) {
        final expense = displayExpenses[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ExpenseListTile(
            expense: expense,
            onDelete: () async {
              await _expenseService.deleteExpense(expense.id);
              setState(() {});
            },
            onEdit: () => _editExpense(expense),
          ),
        );
      },
    );
  }

  void _viewTodayExpenses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyExpensesScreen(
          expenseService: _expenseService,
          selectedDate: DateTime.now(),
        ),
      ),
    );
  }
}
