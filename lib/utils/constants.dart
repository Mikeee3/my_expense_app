class AppConstants {
  static const String fileName = 'expense_data.json';
  static const String backupFileName = 'expense_backup.json';
  
  static const List<String> categories = [
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
    'Other'
  ];

  static const Map<String, String> categoryIcons = {
    'Food & Dining': '🍽️',
    'Transportation': '🚗',
    'Shopping': '🛍️',
    'Bills & Utilities': '📱',
    'Entertainment': '🎬',
    'Healthcare': '🏥',
    'Education': '📚',
    'Personal Care': '💅',
    'Travel': '✈️',
    'Gifts & Donations': '🎁',
    'Other': '📝',
  };
}