import 'package:flutter/material.dart';

class DateFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialFilterType;

  DateFilterDialog({
    this.initialStartDate,
    this.initialEndDate,
    this.initialFilterType,
  });

  @override
  _DateFilterDialogState createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<DateFilterDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _filterType = 'custom';

  final List<Map<String, dynamic>> _quickFilters = [
    {'label': 'Today', 'days': 0},
    {'label': 'Last 7 Days', 'days': 7},
    {'label': 'Last 30 Days', 'days': 30},
    {'label': 'This Month', 'days': -1},
    {'label': 'Last Month', 'days': -2},
    {'label': 'This Year', 'days': -3},
  ];

  @override
  void initState() {
    super.initState();
    _startDate =
        widget.initialStartDate ?? DateTime.now().subtract(Duration(days: 7));
    _endDate = widget.initialEndDate ?? DateTime.now();
    _filterType = widget.initialFilterType ?? 'custom';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _endDate,
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _filterType = 'custom';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _filterType = 'custom';
      });
    }
  }

  void _applyQuickFilter(int days) {
    final now = DateTime.now();

    if (days == -1) {
      // This Month
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    } else if (days == -2) {
      // Last Month
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0);
    } else if (days == -3) {
      // This Year
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, 12, 31);
    } else {
      // Last X days
      _startDate = now.subtract(Duration(days: days));
      _endDate = now;
    }

    setState(() {
      _filterType = days.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter by Date'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Filters
            Text(
              'Quick Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickFilters.map((filter) {
                return FilterChip(
                  label: Text(filter['label']),
                  selected: _filterType == filter['days'].toString(),
                  onSelected: (_) => _applyQuickFilter(filter['days']),
                );
              }).toList(),
            ),

            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),

            Text(
              'Custom Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Start Date
            InkWell(
              onTap: () => _selectStartDate(context),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _formatDate(_startDate),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // End Date
            InkWell(
              onTap: () => _selectEndDate(context),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _formatDate(_endDate),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8),
            Text(
              '${_calculateDays()} days selected',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'startDate': _startDate,
              'endDate': _endDate,
              'filterType': _filterType,
            });
          },
          child: Text('Apply Filter'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateDays() {
    return _endDate.difference(_startDate).inDays + 1;
  }
}
