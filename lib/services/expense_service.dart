import '../models/expense.dart';
import './file_service.dart';

class ExpenseService {
  List<Expense> expenses = [];
  Map<String, dynamic> settings = {};
  Map<String, dynamic> metadata = {};

  ExpenseService() {
    loadData();
  }

  // Core CRUD Operations
  Future<void> addExpense(Expense expense) async {
    expenses.add(expense);
    await saveData();
  }

  Future<void> updateExpense(String id, Expense updatedExpense) async {
    final index = expenses.indexWhere((expense) => expense.id == id);
    if (index != -1) {
      expenses[index] = updatedExpense;
      await saveData();
    }
  }

  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((expense) => expense.id == id);
    await saveData();
  }

  // File Operations
  Future<void> saveData() async {
    metadata['lastUpdated'] = DateTime.now().toIso8601String();

    final data = {
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'settings': settings,
      'metadata': metadata,
    };

    await FileService.saveToJson(data);
    await FileService.createBackup();
  }

  Future<void> loadData() async {
    final data = await FileService.loadFromJson();

    expenses = (data['expenses'] as List)
        .map((e) => Expense.fromJson(e))
        .toList();

    settings = data['settings'] ?? {};
    metadata = data['metadata'] ?? {};
  }

  // Daily Expense Functions
  List<Expense> getTodayExpenses() {
    final today = DateTime.now();
    return expenses.where((expense) {
      return expense.date.year == today.year &&
          expense.date.month == today.month &&
          expense.date.day == today.day;
    }).toList();
  }

  double getTodayTotal() {
    return getTodayExpenses().fold(0, (sum, expense) => sum + expense.amount);
  }

  double getDailyBudgetRemaining() {
    final dailyBudget = (settings['dailyBudget'] ?? 0.0) as double;
    return dailyBudget - getTodayTotal();
  }

  // Filter Functions
  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return expenses.where((expense) {
      return expense.date.isAfter(start.subtract(Duration(days: 1))) &&
          expense.date.isBefore(end.add(Duration(days: 1)));
    }).toList();
  }

  List<Expense> getExpensesByCategory(String category) {
    return expenses.where((expense) => expense.category == category).toList();
  }

  List<Expense> getThisMonthExpenses() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(firstDay, lastDay);
  }

  // Reporting Functions
  Map<String, double> getCategoryTotals() {
    final Map<String, double> totals = {};

    for (var expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  Map<String, dynamic> getMonthlySummary(int month, int year) {
    final monthExpenses = expenses.where((expense) {
      return expense.date.month == month && expense.date.year == year;
    }).toList();

    final total = monthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final count = monthExpenses.length;

    final dailyAvg = count > 0 ? total / DateTime(year, month + 1, 0).day : 0;

    return {
      'total': total,
      'count': count,
      'dailyAverage': dailyAvg,
      'expenses': monthExpenses,
    };
  }

  double getMonthlyTotal() {
    final now = DateTime.now();
    final monthExpenses = getThisMonthExpenses();
    return monthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getMonthlyBudgetRemaining() {
    final monthlyBudget = (settings['monthlyBudget'] ?? 0.0) as double;
    return monthlyBudget - getMonthlyTotal();
  }

  // Search Functions
  List<Expense> searchExpenses(String keyword) {
    if (keyword.isEmpty) return [];

    return expenses.where((expense) {
      return expense.description.toLowerCase().contains(
            keyword.toLowerCase(),
          ) ||
          expense.category.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
  }

  List<Expense> filterByAmount(double min, double max) {
    return expenses.where((expense) {
      return expense.amount >= min && expense.amount <= max;
    }).toList();
  }

  // Sort Functions
  List<Expense> sortByDate({bool descending = true}) {
    final sorted = List<Expense>.from(expenses);
    sorted.sort(
      (a, b) =>
          descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return sorted;
  }

  List<Expense> sortByAmount({bool descending = true}) {
    final sorted = List<Expense>.from(expenses);
    sorted.sort(
      (a, b) => descending
          ? b.amount.compareTo(a.amount)
          : a.amount.compareTo(b.amount),
    );
    return sorted;
  }

  // Analytics Functions
  double getDailyAverage(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentExpenses = expenses
        .where((expense) => expense.date.isAfter(cutoffDate))
        .toList();

    if (recentExpenses.isEmpty) return 0;

    final total = recentExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    return total / days;
  }

  Map<String, double> getWeeklyReport() {
    final Map<String, double> weeklyTotals = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayExpenses = expenses.where((expense) {
        return expense.date.year == date.year &&
            expense.date.month == date.month &&
            expense.date.day == date.day;
      }).toList();

      final total = dayExpenses.fold(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      weeklyTotals[_formatDay(date)] = total;
    }

    return weeklyTotals;
  }

  String _formatDay(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // Budget Functions
  Future<void> setDailyBudget(double amount) async {
    settings['dailyBudget'] = amount;
    await saveData();
  }

  Future<void> setMonthlyBudget(double amount) async {
    settings['monthlyBudget'] = amount;
    await saveData();
  }

  String getBudgetStatus() {
    final dailyRemaining = getDailyBudgetRemaining();
    final monthlyRemaining = getMonthlyBudgetRemaining();

    if (dailyRemaining < 0 && monthlyRemaining < 0) {
      return 'Over budget for both daily and monthly';
    } else if (dailyRemaining < 0) {
      return 'Over daily budget';
    } else if (monthlyRemaining < 0) {
      return 'Over monthly budget';
    } else {
      return 'Within budget';
    }
  }

  // Prediction Function
  double predictMonthEndTotal() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;

    final monthExpenses = getThisMonthExpenses();
    final totalSoFar = monthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    if (daysPassed == 0) return 0;

    final dailyAverage = totalSoFar / daysPassed;
    return dailyAverage * daysInMonth;
  }

  // Data Integrity Functions
  Future<bool> validateData() async {
    try {
      for (var expense in expenses) {
        if (expense.amount <= 0) return false;
        if (expense.date.isAfter(DateTime.now())) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Export Function
  Future<void> exportData() async {
    final exportData = expenses
        .map(
          (e) => {
            'date': e.date.toIso8601String(),
            'amount': e.amount,
            'category': e.category,
            'description': e.description,
          },
        )
        .toList();

    await FileService.exportToCsv(exportData);
  }

  // Quick budget suggestions
  Map<String, double> getBudgetSuggestions() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthExpenses = getExpensesByDateRange(
      lastMonth,
      DateTime(now.year, now.month, 0),
    );

    final total = lastMonthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final dailyAvg = total / 30;

    return {
      'basedOnLastMonth': total,
      'suggestedDaily': (dailyAvg * 1.1).roundToDouble(),
      'suggestedMonthly': (total * 1.1).roundToDouble(),
    };
  }

  // Validate budget
  String? validateBudget(double amount, String type) {
    if (amount <= 0) return '$type must be greater than 0';
    if (amount > 1000000) return '$type is too large';
    return null;
  }

  // Get budget statistics
  Map<String, dynamic> getBudgetStatistics() {
    final dailyBudget = settings['dailyBudget'] ?? 50.0;
    final monthlyBudget = settings['monthlyBudget'] ?? 1500.0;
    final todayTotal = getTodayTotal();
    final monthlyTotal = getMonthlyTotal();

    final dailyPercentage = (todayTotal / dailyBudget * 100).clamp(0, 100);
    final monthlyPercentage = (monthlyTotal / monthlyBudget * 100).clamp(
      0,
      100,
    );

    return {
      'daily': {
        'budget': dailyBudget,
        'spent': todayTotal,
        'remaining': dailyBudget - todayTotal,
        'percentage': dailyPercentage,
        'status': dailyPercentage >= 100
            ? 'Exceeded'
            : dailyPercentage >= 90
            ? 'Critical'
            : dailyPercentage >= 75
            ? 'Warning'
            : 'Good',
      },
      'monthly': {
        'budget': monthlyBudget,
        'spent': monthlyTotal,
        'remaining': monthlyBudget - monthlyTotal,
        'percentage': monthlyPercentage,
        'status': monthlyPercentage >= 100
            ? 'Exceeded'
            : monthlyPercentage >= 90
            ? 'Critical'
            : monthlyPercentage >= 75
            ? 'Warning'
            : 'Good',
      },
    };
  }
}
