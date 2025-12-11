import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:my_expense_app/models/expense.dart';
import '../services/expense_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/date_filter_dialog.dart';
import 'daily_expenses_screen.dart';

class ReportsScreen extends StatefulWidget {
  final ExpenseService expenseService;

  const ReportsScreen({required this.expenseService, Key? key})
    : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _filterType = '7';

  late List<Expense> _filteredExpenses;
  late Map<String, double> _categoryTotals;
  late Map<String, double> _dailyTotals;
  late List<Expense> _sortedExpenses;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _filteredExpenses = widget.expenseService.getExpensesByDateRange(
      _startDate,
      _endDate,
    );
    _calculateCategoryTotals();
    _calculateDailyTotals();
    _sortedExpenses = List<Expense>.from(_filteredExpenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  void _calculateCategoryTotals() {
    _categoryTotals = {};
    for (var expense in _filteredExpenses) {
      _categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
  }

  void _calculateDailyTotals() {
    _dailyTotals = {};
    final daysInRange = _endDate.difference(_startDate).inDays + 1;

    if (daysInRange <= 30) {
      // Changed from 60 to 30 for better daily view
      // Daily data
      for (var i = 0; i < daysInRange; i++) {
        final date = _startDate.add(Duration(days: i));
        final key = _formatDailyKey(date);
        _dailyTotals[key] = _getDailyTotal(date);
      }
    } else if (daysInRange <= 180) {
      // Changed threshold
      // Weekly data
      _dailyTotals = _getWeeklyTotals();
    } else {
      // Monthly data
      _dailyTotals = _getMonthlyTotals();
    }
  }

  String _formatDailyKey(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }

  double _getDailyTotal(DateTime date) {
    return _filteredExpenses
        .where((expense) => Helpers.isSameDay(expense.date, date))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> _getWeeklyTotals() {
    final weeklyTotals = <String, double>{};
    for (var i = 0; i <= _endDate.difference(_startDate).inDays; i += 7) {
      final startDate = _startDate.add(Duration(days: i));
      final endDate = startDate.add(const Duration(days: 6));
      if (endDate.isAfter(_endDate)) break;

      final key = '${_formatDailyKey(startDate)}-${_formatDailyKey(endDate)}';
      weeklyTotals[key] = _getWeeklyTotal(startDate, endDate);
    }
    return weeklyTotals;
  }

  double _getWeeklyTotal(DateTime startDate, DateTime endDate) {
    return _filteredExpenses
        .where(
          (expense) =>
              expense.date.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              expense.date.isBefore(endDate.add(const Duration(days: 1))),
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> _getMonthlyTotals() {
    final monthlyTotals = <String, double>{};
    final monthYearSet = <String>{};

    for (var expense in _filteredExpenses) {
      final key = DateFormat('MMM yyyy').format(expense.date);
      monthYearSet.add(key);
    }

    final sortedMonths = monthYearSet.toList()
      ..sort(
        (a, b) => DateFormat(
          'MMM yyyy',
        ).parse(a).compareTo(DateFormat('MMM yyyy').parse(b)),
      );

    for (var monthYear in sortedMonths) {
      final date = DateFormat('MMM yyyy').parse(monthYear);
      final monthTotal = _filteredExpenses
          .where(
            (expense) =>
                expense.date.month == date.month &&
                expense.date.year == date.year,
          )
          .fold(0.0, (sum, expense) => sum + expense.amount);
      monthlyTotals[monthYear] = monthTotal;
    }

    return monthlyTotals;
  }

  Future<void> _showDateFilter() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DateFilterDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        initialFilterType: _filterType,
      ),
    );

    if (result != null) {
      setState(() {
        _startDate = result['startDate'];
        _endDate = result['endDate'];
        _filterType = result['filterType'];
        _refreshData();
      });
    }
  }

  void _viewDailyExpenses(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyExpensesScreen(
          expenseService: widget.expenseService,
          selectedDate: date,
        ),
      ),
    );
  }

  double get _totalSpent {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get _averageDailySpent {
    final days = _endDate.difference(_startDate).inDays + 1;
    return days > 0 ? _totalSpent / days : 0;
  }

  Map<String, double> get _groupedChartData {
    final daysInRange = _endDate.difference(_startDate).inDays + 1;
    if (daysInRange <= 30) return _dailyTotals;
    if (daysInRange <= 180) return _dailyTotals; // Already grouped by week
    return _getMonthlyTotals();
  }

  String get _chartTitle {
    final daysInRange = _endDate.difference(_startDate).inDays + 1;
    if (daysInRange <= 30) return 'Daily Spending';
    if (daysInRange <= 180) return 'Weekly Spending';
    return 'Monthly Spending';
  }

  @override
  Widget build(BuildContext context) {
    final daysInRange = _endDate.difference(_startDate).inDays + 1;
    final isChartLongPeriod = daysInRange > 30;
    final chartData = _groupedChartData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showDateFilter,
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Header
            _buildSummaryHeader(daysInRange),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _refreshData());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Spending Chart
                      if (chartData.isNotEmpty)
                        _buildSpendingChart(chartData, isChartLongPeriod),

                      // Category Breakdown
                      if (_categoryTotals.isNotEmpty) _buildCategoryChart(),

                      // Top Expenses
                      if (_sortedExpenses.isNotEmpty) _buildTopExpenses(),

                      // Statistics Cards
                      _buildStatisticsCards(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(int daysInRange) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildDateRange(), _buildTotalAmount()],
          ),
          const SizedBox(height: 8),
          _buildStatsRow(daysInRange),
        ],
      ),
    );
  }

  Widget _buildDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERIOD',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${Helpers.formatDate(_startDate, format: 'MMM dd')} - ${Helpers.formatDate(_endDate, format: 'MMM dd')}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'TOTAL SPENT',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '\$${_totalSpent.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int daysInRange) {
    return Row(
      children: [
        _buildStatChip(icon: Icons.calendar_today, label: '$daysInRange days'),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.receipt,
          label: '${_filteredExpenses.length} expenses',
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.trending_up,
          label: '\$${_averageDailySpent.toStringAsFixed(2)}/day',
        ),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: Icon(icon, size: 14),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSpendingChart(Map<String, double> chartData, bool isLongPeriod) {
    final chartEntries = chartData.entries.toList();
    final maxValue = chartData.values.fold(
      0.0,
      (max, value) => value > max ? value : max,
    );
    final maxY = maxValue * 1.2;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _chartTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // if (chartData.length > 5)
                //   IconButton(
                //     icon: const Icon(Icons.zoom_out_map, size: 20),
                //     onPressed: _showFullChart,
                //     padding: EdgeInsets.zero,
                //     constraints: const BoxConstraints(minWidth: 36),
                //   ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: \$${_totalSpent.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: maxY,
                  minY: 0,
                  barGroups: _buildBarGroups(chartEntries),
                  titlesData: _buildTitlesData(chartEntries, isLongPeriod),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = chartEntries[group.x.toInt()].key;
                        final value = rod.toY;
                        return BarTooltipItem(
                          '$label\n\$${value.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      if (response != null && response.spot != null) {
                        final index = response.spot!.touchedBarGroupIndex;
                        if (index < chartEntries.length && isLongPeriod) {
                          _showPeriodDetails(chartEntries[index].key);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                isLongPeriod
                    ? 'Tap bars for details • Touch & hold for values'
                    : 'Touch & hold bars for details',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<MapEntry<String, double>> entries,
  ) {
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isToday = _isTodayOrCurrentPeriod(data.key);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value,
            color: data.value > 0
                ? (isToday ? Colors.orange : Theme.of(context).primaryColor)
                : Colors.grey[300]!,
            width: 12,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _totalSpent / entries.length,
              color: Colors.grey[100],
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  bool _isTodayOrCurrentPeriod(String periodKey) {
    final now = DateTime.now();
    final daysInRange = _endDate.difference(_startDate).inDays + 1;

    if (daysInRange <= 30) {
      final date = DateFormat('MM/dd').parse(periodKey);
      return Helpers.isSameDay(date, now);
    } else if (daysInRange <= 180) {
      // Check if current week
      return periodKey.contains(DateFormat('MM/dd').format(now));
    }
    return false;
  }

  FlTitlesData _buildTitlesData(
    List<MapEntry<String, double>> entries,
    bool isLongPeriod,
  ) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() < entries.length) {
              final label = entries[value.toInt()].key;
              final displayText = isLongPeriod && label.length > 8
                  ? label.substring(0, 7) + '...'
                  : label;

              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Transform.rotate(
                  angle: isLongPeriod ? 0 : -0.5,
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: isLongPeriod ? 10 : 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }
            return const SizedBox();
          },
          reservedSize: isLongPeriod ? 30 : 25,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value <= 0) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(
                '\$${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              ),
            );
          },
          reservedSize: 40,
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildCategoryChart() {
    final sortedCategories = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  // Pie Chart
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sortedCategories.map((entry) {
                          final percentage = _totalSpent > 0
                              ? (entry.value / _totalSpent * 100)
                              : 0;

                          return PieChartSectionData(
                            color: Helpers.getCategoryColor(entry.key),
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            badgeWidget: _buildCategoryBadge(entry.key),
                            badgePositionPercentageOffset: 0.98,
                          );
                        }).toList(),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),

                  // Legend
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: sortedCategories.map((entry) {
                          final double percentage = _totalSpent > 0
                              ? (entry.value / _totalSpent * 100)
                              : 0;

                          return _buildLegendItem(
                            entry.key,
                            entry.value,
                            percentage,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white,
      child: Text(
        AppConstants.categoryIcons[category] ?? '📝',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildLegendItem(String category, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Helpers.getCategoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpenses() {
    final topExpenses = _sortedExpenses.take(5).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...topExpenses.map((expense) => _buildExpenseItem(expense)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Helpers.getCategoryColor(
            expense.category,
          ).withOpacity(0.1),
          child: Text(
            AppConstants.categoryIcons[expense.category] ?? '📝',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.description.isNotEmpty)
              Text(
                expense.description,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              Helpers.formatDate(expense.date),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            _buildExpenseIndicator(expense.amount),
          ],
        ),
        onTap: () => _viewDailyExpenses(expense.date),
      ),
    );
  }

  Widget _buildExpenseIndicator(double amount) {
    final maxAmount = _sortedExpenses.isNotEmpty
        ? _sortedExpenses.first.amount
        : amount;
    final width = (amount / maxAmount * 40).clamp(10.0, 40.0);

    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: amount > (maxAmount * 0.7)
            ? Colors.red
            : amount > (maxAmount * 0.3)
            ? Colors.orange
            : Colors.green,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final highestExpense = _sortedExpenses.isNotEmpty
        ? _sortedExpenses.first
        : null;
    final lowestExpense = _sortedExpenses.isNotEmpty
        ? _sortedExpenses.last
        : null;
    final daysInRange = _endDate.difference(_startDate).inDays + 1;

    final stats = [
      _StatCardData(
        title: 'Total Expenses',
        value: '${_filteredExpenses.length}',
        icon: Icons.receipt,
        color: Colors.blue,
      ),
      _StatCardData(
        title: 'Total Amount',
        value: '\$${_totalSpent.toStringAsFixed(2)}',
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      _StatCardData(
        title: 'Daily Average',
        value: '\$${_averageDailySpent.toStringAsFixed(2)}',
        icon: Icons.trending_up,
        color: Colors.orange,
      ),
      _StatCardData(
        title: 'Days in Range',
        value: '$daysInRange',
        icon: Icons.calendar_today,
        color: Colors.purple,
      ),
      if (highestExpense != null)
        _StatCardData(
          title: 'Highest Expense',
          value: '\$${highestExpense.amount.toStringAsFixed(2)}',
          icon: Icons.arrow_upward,
          color: Colors.red,
        ),
      if (lowestExpense != null)
        _StatCardData(
          title: 'Lowest Expense',
          value: '\$${lowestExpense.amount.toStringAsFixed(2)}',
          icon: Icons.arrow_downward,
          color: Colors.teal,
        ),
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: stats.map((stat) => _buildStatCard(stat)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    final width = (MediaQuery.of(context).size.width - 64) / 2;

    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: data.color.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: data.color.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(data.icon, size: 16, color: data.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.title,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: data.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _showFullChart() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return Dialog(
  //         insetPadding: const EdgeInsets.all(16),
  //         child: ConstrainedBox(
  //           constraints: const BoxConstraints(maxHeight: 500),
  //           child: Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   _chartTitle,
  //                   style: const TextStyle(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Expanded(
  //                   child: _buildSpendingChart(
  //                     _groupedChartData,
  //                     _endDate.difference(_startDate).inDays + 1 > 30,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 ElevatedButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   child: const Text('Close'),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showPeriodDetails(String periodKey) {
    final daysInRange = _endDate.difference(_startDate).inDays + 1;

    if (daysInRange <= 30) {
      // Show daily details
      final date = DateFormat('MM/dd').parse(periodKey);
      _viewDailyExpenses(date);
    // } else if (daysInRange <= 180) {
    //   // Show weekly details
    //   _showWeeklyDetails(periodKey);
    } else {
      // Show monthly details
      _showMonthlyDetails(periodKey);
    }
  }

  // void _showWeeklyDetails(String weekRange) {
  //   final parts = weekRange.split('-');
  //   if (parts.length != 2) return;

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Week: $weekRange'),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           child: ListView(
  //             shrinkWrap: true,
  //             children: [
  //               // Add weekly breakdown content
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _showMonthlyDetails(String monthYear) {
    // Implement monthly details view
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
