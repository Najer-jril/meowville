const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _two(int value) => value.toString().padLeft(2, '0');

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime parseDateOnly(String value) {
  final List<String> parts = value.split('T').first.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime parseServerTimestamp(String value) {
  final bool hasZone =
      value.endsWith('Z') || RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}

String formatSqlDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${_two(value.month)}-${_two(value.day)}';

int daysBetween(DateTime from, DateTime to) {
  return DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

String formatShortDate(DateTime value, {bool withYear = true}) {
  final String base = '${value.day} ${_months[value.month - 1]}';
  return withYear ? '$base ${value.year}' : base;
}

String relativeDate(DateTime date, {required DateTime today}) {
  final int diff = daysBetween(today, date);
  if (diff == 0) {
    return 'Hari ini';
  }
  if (diff == 1) {
    return 'Besok';
  }
  if (diff == -1) {
    return 'Kemarin';
  }
  if (diff >= 2 && diff <= 6) {
    return '$diff hari lagi';
  }
  if (diff <= -2 && diff >= -6) {
    return '${-diff} hari lalu';
  }
  return formatShortDate(date);
}

String relativeTime(DateTime timestamp, {required DateTime now}) {
  final Duration diff = now.difference(timestamp);
  if (diff.inMinutes < 1) {
    return 'Baru saja';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} menit lalu';
  }
  if (diff.inHours < 24 && now.day == timestamp.day) {
    return '${diff.inHours} jam lalu';
  }
  return relativeDate(dateOnly(timestamp), today: dateOnly(now));
}

String stayRange(DateTime checkin, DateTime checkout) {
  final int nights = daysBetween(checkin, checkout);
  final String range;
  if (checkin.year != checkout.year) {
    range = '${formatShortDate(checkin)} - ${formatShortDate(checkout)}';
  } else if (checkin.month == checkout.month) {
    range = '${checkin.day} - ${formatShortDate(checkout, withYear: false)}';
  } else {
    range =
        '${formatShortDate(checkin, withYear: false)} - '
        '${formatShortDate(checkout, withYear: false)}';
  }
  return '$range - $nights malam';
}

String formatRupiah(num amount) {
  final String digits = amount.round().abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}
