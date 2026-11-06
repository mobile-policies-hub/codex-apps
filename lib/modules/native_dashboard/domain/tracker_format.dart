const weekDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatLongDate(
  DateTime date, [
  String Function(String english)? translate,
]) {
  final tr = translate ?? (String value) => value;
  return '${tr(_weekdays[date.weekday - 1])}, ${tr(_months[date.month - 1])} ${date.day}';
}

String formatCount(int value) {
  final digits = value.abs().toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.add(digits.substring(start, end));
  }
  final formatted = groups.reversed.join('\u00A0');
  return value < 0 ? '-$formatted' : formatted;
}

String formatKilometers(double value) {
  return value.toStringAsFixed(1);
}

String pluralize(int value, String singular, String plural) {
  return value.abs() == 1 ? singular : plural;
}
