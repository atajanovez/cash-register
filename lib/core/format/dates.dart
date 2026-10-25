/// Turkmen date formatting. Neither `intl` nor Flutter ships Turkmen date
/// data, so month and weekday names live here.
abstract final class Dates {
  static const months = [
    'ýanwar',
    'fewral',
    'mart',
    'aprel',
    'maý',
    'iýun',
    'iýul',
    'awgust',
    'sentýabr',
    'oktýabr',
    'noýabr',
    'dekabr',
  ];

  /// Monday first, matching [DateTime.weekday] (1 = Monday).
  static const weekdays = [
    'duşenbe',
    'sişenbe',
    'çarşenbe',
    'penşenbe',
    'anna',
    'şenbe',
    'ýekşenbe',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `02.11.2026`
  static String date(DateTime value) {
    final d = value.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year}';
  }

  /// `20:07`
  static String time(DateTime value) {
    final d = value.toLocal();
    return '${_two(d.hour)}:${_two(d.minute)}';
  }

  /// `02.11.2026, 20:07`
  static String dateTime(DateTime value) => '${date(value)}, ${time(value)}';

  /// `2 noýabr` this year, `02.11.2027` otherwise; for tight spaces.
  static String short(DateTime value, {DateTime? now}) {
    final d = value.toLocal();
    return d.year == (now ?? DateTime.now()).year
        ? '${d.day} ${months[d.month - 1]}'
        : date(d);
  }

  /// [today] / [yesterday] labels, otherwise e.g. `Duşenbe, 19 oktýabr`.
  static String dayHeader(
    DateTime value, {
    required String today,
    required String yesterday,
    DateTime? now,
  }) {
    final local = value.toLocal();
    final diff = _day(now ?? DateTime.now()).difference(_day(local)).inDays;
    if (diff == 0) return today;
    if (diff == 1) return yesterday;
    final weekday = weekdays[local.weekday - 1];
    final year = local.year == (now ?? DateTime.now()).year
        ? ''
        : ' ${local.year}';
    return '${weekday[0].toUpperCase()}${weekday.substring(1)}, '
        '${local.day} ${months[local.month - 1]}$year';
  }

  static bool sameDay(DateTime a, DateTime b) =>
      _day(a.toLocal()) == _day(b.toLocal());

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
