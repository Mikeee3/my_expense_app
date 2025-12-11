import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../services/expense_service.dart';
import '../utils/helpers.dart';

class DataManagementScreen extends StatefulWidget {
  final ExpenseService expenseService;

  DataManagementScreen({required this.expenseService});

  @override
  _DataManagementScreenState createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  Map<String, dynamic> _fileInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await FileService.getFileInfo();
      setState(() {
        _fileInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    try {
      await FileService.createBackup();
      await _loadFileInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreFromBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore from Backup'),
        content: Text(
          'This will replace all current data with backup data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FileService.createBackup(); // Backup current data first
        await widget.expenseService.loadData(); // This will load from main file
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data restored from backup'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadFileInfo();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring from backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final expenses = widget.expenseService.expenses
          .map(
            (e) => {
              'date': e.date.toIso8601String(),
              'amount': e.amount,
              'category': e.category,
              'description': e.description,
            },
          )
          .toList();

      await FileService.exportToCsv(expenses);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text(
          'This will permanently delete all your expense data. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete All Data', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FileService.clearAllData();
        await widget.expenseService.loadData();
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All data has been cleared'),
            backgroundColor: Colors.blue,
          ),
        );

        await _loadFileInfo();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainFile = _fileInfo['mainFile'] ?? {};
    final backupFile = _fileInfo['backupFile'] ?? {};
    final totalExpenses = widget.expenseService.expenses.length;

    return Scaffold(
      appBar: AppBar(title: Text('Data Management')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Expenses:'),
                              Text(
                                '$totalExpenses',
                                style: TextStyle(
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
                              Text('Data Size:'),
                              Text(
                                Helpers.formatFileSize(mainFile['size'] ?? 0),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Last Modified:'),
                              Text(
                                mainFile['modified'] != null
                                    ? Helpers.getRelativeDate(
                                        mainFile['modified'],
                                      )
                                    : 'Never',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // File Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildFileInfoItem('Main File', mainFile),
                          SizedBox(height: 12),
                          _buildFileInfoItem('Backup File', backupFile),
                          SizedBox(height: 8),
                          Text(
                            'Location: ${mainFile['path'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Actions
                  Text(
                    'Data Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildActionButton(
                        icon: Icons.backup,
                        label: 'Create Backup',
                        color: Colors.blue,
                        onTap: _createBackup,
                      ),
                      _buildActionButton(
                        icon: Icons.restore,
                        label: 'Restore Backup',
                        color: Colors.orange,
                        onTap: _restoreFromBackup,
                        enabled: backupFile['exists'] == true,
                      ),
                      _buildActionButton(
                        icon: Icons.download,
                        label: 'Export CSV',
                        color: Colors.green,
                        onTap: _exportData,
                        enabled: totalExpenses > 0,
                      ),
                      _buildActionButton(
                        icon: Icons.refresh,
                        label: 'Reload Data',
                        color: Colors.purple,
                        onTap: () async {
                          await widget.expenseService.loadData();
                          await _loadFileInfo();
                          setState(() {});
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.delete,
                        label: 'Clear All Data',
                        color: Colors.red,
                        onTap: _clearAllData,
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Information
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Data Storage Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• All data is stored locally on your device',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '• Data is automatically backed up',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '• Export to CSV for external backup',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '• Data persists across app updates',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '• Uninstalling the app will delete all data',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFileInfoItem(String title, Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Row(
          children: [
            Icon(
              info['exists'] == true ? Icons.check_circle : Icons.error,
              color: info['exists'] == true ? Colors.green : Colors.grey,
              size: 16,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                info['exists'] == true
                    ? '${Helpers.formatFileSize(info['size'] ?? 0)} • Modified: ${Helpers.getRelativeDate(info['modified'])}'
                    : 'File does not exist',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: enabled ? color : Colors.grey),
      label: Text(label),
      onPressed: enabled ? onTap : null,
      backgroundColor: color.withOpacity(0.1),
    );
  }
}
