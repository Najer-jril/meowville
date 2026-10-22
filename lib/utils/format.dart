class Fmt {
  Fmt._();

  static const _months = [
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
  static const _monthsLong = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String rupiah(int value) => 'Rp ${thousands(value)}';

  static String thousands(int value) {
    final s = value.abs().toString();
    final out = s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return value < 0 ? '-$out' : out;
  }

  static String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String date(DateTime d) => '${dayMonth(d)} ${d.year}';

  static String dateLong(DateTime d) => '${_days[d.weekday - 1]}, ${date(d)}';

  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static String monthYear(DateTime d) =>
      '${_monthsLong[d.month - 1]} ${d.year}';

  static String range(DateTime a, DateTime b) {
    if (a.month == b.month && a.year == b.year) {
      return '${a.day} - ${dayMonth(b)}';
    }
    return '${dayMonth(a)} - ${dayMonth(b)}';
  }

  static String ago(DateTime from, DateTime now) {
    final diff = now.difference(from);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
