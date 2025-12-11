import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  // Date Formatting
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(dateTime);
  }

  // Currency Formatting
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    ).format(amount);
  }

  static String formatCompactCurrency(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Calculation Helpers
  static double calculatePercentage(double part, double whole) {
    return whole > 0 ? (part / whole) * 100 : 0;
  }

  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return formatDate(date);
    }
  }

  // Color Helpers
  static Color getColorForAmount(double amount) {
    if (amount < 10) return Colors.green;
    if (amount < 50) return Colors.blue;
    if (amount < 100) return Colors.orange;
    return Colors.red;
  }

  static Color getCategoryColor(String category) {
    final colors = {
      'Food & Dining': Colors.redAccent,
      'Transportation': Colors.blueAccent,
      'Shopping': Colors.greenAccent,
      'Bills & Utilities': Colors.orangeAccent,
      'Entertainment': Colors.purpleAccent,
      'Healthcare': Colors.pinkAccent,
      'Education': Colors.tealAccent,
      'Personal Care': Colors.deepOrangeAccent,
      'Travel': Colors.lightBlueAccent,
      'Gifts & Donations': Colors.lightGreenAccent,
      'Other': Colors.grey,
    };

    return colors[category] ?? Colors.grey;
  }

  // File Size Formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  // Validation Helpers
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static List<DateTime> getDaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final days = <DateTime>[];

    for (var i = 0; i <= lastDay.difference(firstDay).inDays; i++) {
      days.add(firstDay.add(Duration(days: i)));
    }

    return days;
  }

  // String Helpers
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String truncateWithEllipsis(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  }

  // Notification Messages
  static String getBudgetNotification(double spent, double budget) {
    final percentage = (spent / budget) * 100;

    if (percentage >= 100) {
      return 'You have exceeded your budget!';
    } else if (percentage >= 90) {
      return 'You\'re almost at your budget limit!';
    } else if (percentage >= 75) {
      return 'You\'ve used 75% of your budget';
    } else if (percentage >= 50) {
      return 'You\'ve used half of your budget';
    } else {
      return 'You\'re within your budget';
    }
  }

  // Time Helpers
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  // Export Helpers
  static String generateExportFilename() {
    final now = DateTime.now();
    return 'expenses_${now.year}_${now.month}_${now.day}_${now.hour}${now.minute}.csv';
  }
}
