import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/core/utils/relative_date.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 12);

  group('relativeDate', () {
    test('menyebut hari ini, besok, dan kemarin', () {
      expect(relativeDate(DateTime(2026, 10, 12), today: today), 'Hari ini');
      expect(relativeDate(DateTime(2026, 10, 13), today: today), 'Besok');
      expect(relativeDate(DateTime(2026, 10, 11), today: today), 'Kemarin');
    });

    test('menghitung hari lagi dan hari lalu sampai enam hari', () {
      expect(relativeDate(DateTime(2026, 10, 14), today: today), '2 hari lagi');
      expect(relativeDate(DateTime(2026, 10, 18), today: today), '6 hari lagi');
      expect(relativeDate(DateTime(2026, 10, 10), today: today), '2 hari lalu');
      expect(relativeDate(DateTime(2026, 10, 6), today: today), '6 hari lalu');
    });

    test('memakai tanggal penuh untuk selisih lebih dari enam hari', () {
      expect(relativeDate(DateTime(2026, 10, 19), today: today), '19 Okt 2026');
      expect(relativeDate(DateTime(2026, 10, 5), today: today), '5 Okt 2026');
    });

    test('tahan terhadap pergantian bulan dan tahun', () {
      expect(
        relativeDate(DateTime(2027, 1, 1), today: DateTime(2026, 12, 31)),
        'Besok',
      );
    });
  });

  group('stayRange', () {
    test('menulis rentang dalam satu bulan', () {
      expect(
        stayRange(DateTime(2026, 10, 12), DateTime(2026, 10, 15)),
        '12 - 15 Okt - 3 malam',
      );
    });

    test('menulis kedua bulan saat rentang melintasi bulan', () {
      expect(
        stayRange(DateTime(2026, 9, 30), DateTime(2026, 10, 2)),
        '30 Sep - 2 Okt - 2 malam',
      );
    });

    test('menulis tahun saat rentang melintasi tahun', () {
      expect(
        stayRange(DateTime(2026, 12, 30), DateTime(2027, 1, 2)),
        '30 Des 2026 - 2 Jan 2027 - 3 malam',
      );
    });
  });

  group('relativeTime', () {
    final DateTime now = DateTime(2026, 10, 12, 14, 0);

    test('memilih satuan menurut selisih', () {
      expect(
        relativeTime(DateTime(2026, 10, 12, 13, 59, 40), now: now),
        'Baru saja',
      );
      expect(
        relativeTime(DateTime(2026, 10, 12, 13, 30), now: now),
        '30 menit lalu',
      );
      expect(
        relativeTime(DateTime(2026, 10, 12, 9, 0), now: now),
        '5 jam lalu',
      );
      expect(relativeTime(DateTime(2026, 10, 11, 20, 0), now: now), 'Kemarin');
    });
  });

  test('parseServerTimestamp membaca timestamp tanpa zona sebagai UTC', () {
    final DateTime parsed = parseServerTimestamp('2026-10-10T02:00:00.123');
    expect(parsed.toUtc(), DateTime.utc(2026, 10, 10, 2, 0, 0, 123));
  });

  test('parseDateOnly dan formatSqlDate saling membalik', () {
    expect(formatSqlDate(parseDateOnly('2026-10-05')), '2026-10-05');
  });

  test('formatRupiah memakai titik pemisah ribuan', () {
    expect(formatRupiah(225000), 'Rp 225.000');
    expect(formatRupiah(1250000), 'Rp 1.250.000');
    expect(formatRupiah(0), 'Rp 0');
  });
}
