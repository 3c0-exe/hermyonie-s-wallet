import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_PH');
    return '₱${formatter.format(amount)}';
  }

  static String date(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}