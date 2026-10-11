const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a date for display, for example "11 Oct 2026".
String formatDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

/// Returns the same day with the time set to midnight, so two dates can be
/// compared by calendar day.
DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
