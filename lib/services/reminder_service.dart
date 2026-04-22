import 'package:shared_preferences/shared_preferences.dart';

class ReminderService {
  static const _key = 'last_reminder_dismissed';

  static Future<bool> shouldShowReminder() async {
    final now = DateTime.now();
    // Only on 15th and 30th (or last day of month)
    final isReminderDay = now.day == 15 || now.day == 30 ||
        now.day == _lastDayOfMonth(now.year, now.month);
    if (!isReminderDay) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastDismissed = prefs.getString(_key);
    if (lastDismissed == null) return true;

    final last = DateTime.tryParse(lastDismissed);
    if (last == null) return true;

    // Don't show again if already dismissed today
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    return today.isAfter(lastDay);
  }

  static Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, DateTime.now().toIso8601String());
  }

  static int _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}