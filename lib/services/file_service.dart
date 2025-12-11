import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileService {
  static const String fileName = 'expense_data.json';
  static const String backupFileName = 'expense_backup.json';

  static Future<String> get _localPath async {
    if (kIsWeb) {
      throw Exception('Web not supported in this version');
    }

    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<File> get _backupFile async {
    final path = await _localPath;
    return File('$path/$backupFileName');
  }

  static Future<void> saveToJson(Map<String, dynamic> data) async {
    try {
      final file = await _localFile;
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);

      // Also create a backup
      await createBackup();
    } catch (e) {
      print('Error saving file: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> loadFromJson() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
      return createInitialData();
    } catch (e) {
      print('Error loading file: $e');
      // Try to restore from backup
      return await _restoreFromBackup() ?? createInitialData();
    }
  }

  static Future<void> createBackup() async {
    try {
      final source = await _localFile;
      final backup = await _backupFile;

      if (await source.exists()) {
        final contents = await source.readAsString();
        await backup.writeAsString(contents);
      }
    } catch (e) {
      print('Error creating backup: $e');
    }
  }

  static Future<Map<String, dynamic>?> _restoreFromBackup() async {
    try {
      final backup = await _backupFile;
      if (await backup.exists()) {
        final contents = await backup.readAsString();
        return jsonDecode(contents);
      }
      return null;
    } catch (e) {
      print('Error restoring from backup: $e');
      return null;
    }
  }

  static Future<void> exportToCsv(List<Map<String, dynamic>> data) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      final exportDir = Directory('${directory.path}/ExpenseExports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${exportDir.path}/expenses_$timestamp.csv');

      String csvContent = 'Date,Amount,Category,Description\n';
      for (var expense in data) {
        csvContent +=
            '"${expense['date']}",'
            '"${expense['amount']}",'
            '"${expense['category']}",'
            '"${expense['description']}"\n';
      }

      await file.writeAsString(csvContent);

      // On mobile, we could show a dialog with the file path
    } catch (e) {
      print('Error exporting CSV: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> createInitialData() {
    return {
      'expenses': [],
      'settings': {
        'dailyBudget': 50.0,
        'monthlyBudget': 1500.0,
        'currency': 'USD',
        'categories': [
          'Food & Dining',
          'Transportation',
          'Shopping',
          'Bills & Utilities',
          'Entertainment',
          'Healthcare',
          'Education',
          'Personal Care',
          'Travel',
          'Gifts & Donations',
          'Other',
        ],
      },
      'metadata': {
        'createdAt': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
        'version': '1.0',
      },
    };
  }

  // New method to get file info
  static Future<Map<String, dynamic>> getFileInfo() async {
    try {
      final file = await _localFile;
      final backup = await _backupFile;

      final mainExists = await file.exists();
      final backupExists = await backup.exists();

      int mainSize = 0;
      int backupSize = 0;
      DateTime? mainModified;
      DateTime? backupModified;

      if (mainExists) {
        final stat = await file.stat();
        mainSize = stat.size;
        mainModified = stat.modified;
      }

      if (backupExists) {
        final stat = await backup.stat();
        backupSize = stat.size;
        backupModified = stat.modified;
      }

      return {
        'mainFile': {
          'exists': mainExists,
          'size': mainSize,
          'modified': mainModified,
          'path': file.path,
        },
        'backupFile': {
          'exists': backupExists,
          'size': backupSize,
          'modified': backupModified,
          'path': backup.path,
        },
      };
    } catch (e) {
      print('Error getting file info: $e');
      return {
        'mainFile': {'exists': false, 'size': 0, 'path': 'Error'},
        'backupFile': {'exists': false, 'size': 0, 'path': 'Error'},
      };
    }
  }

  // New method to clear all data
  static Future<void> clearAllData() async {
    try {
      final file = await _localFile;
      final backup = await _backupFile;

      if (await file.exists()) {
        await file.delete();
      }

      if (await backup.exists()) {
        await backup.delete();
      }
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // New method to migrate data from old format
  static Future<void> migrateDataIfNeeded() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) return;

      final contents = await file.readAsString();
      final data = jsonDecode(contents);

      // Check if data needs migration (add new fields, etc.)
      if (!data.containsKey('metadata')) {
        data['metadata'] = {
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
          'version': '1.0',
        };
        await saveToJson(data);
      }
    } catch (e) {
      print('Error migrating data: $e');
    }
  }
}
