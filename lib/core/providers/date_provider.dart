import 'package:flutter_riverpod/legacy.dart';

/// Riverpod state provider for the currently selected calendar filter date.
/// Defaults to current date (today).
final selectedDateProvider = StateProvider<DateTime?>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Utility helper functions for date comparisons
bool isSameDay(DateTime? d1, DateTime? d2) {
  if (d1 == null || d2 == null) return false;
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

bool matchesSelectedDate(String? rawDateStr, DateTime? selectedDate) {
  if (selectedDate == null) return true; // No date filter active -> show all
  if (rawDateStr == null || rawDateStr.isEmpty) return false;
  try {
    final parsed = DateTime.parse(rawDateStr);
    return isSameDay(parsed, selectedDate);
  } catch (_) {
    return false;
  }
}
