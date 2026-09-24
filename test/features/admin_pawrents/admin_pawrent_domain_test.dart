import 'package:flutter_test/flutter_test.dart';
import 'package:meowville/features/admin_pawrents/data/models/pawrent_dto.dart';
import 'package:meowville/features/admin_pawrents/domain/entities/pawrent.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';

void main() {
  const PawrentSummary citra = PawrentSummary(
    id: 'a',
    name: 'Citra Lestari',
    email: 'citra.lestari@contoh.com',
    petCount: 2,
    bookingStatuses: <BookingStatus>[
      BookingStatus.checkedIn,
      BookingStatus.cancelled,
    ],
  );
  const PawrentSummary reza = PawrentSummary(
    id: 'b',
    name: 'Reza Gunawan',
    email: 'reza@contoh.com',
    petCount: 1,
    bookingStatuses: <BookingStatus>[BookingStatus.checkedOut],
  );

  group('PawrentSummary', () {
    test('menginap hanya bila ada reservasi CheckedIn', () {
      expect(citra.isStaying, isTrue);
      expect(reza.isStaying, isFalse);
      expect(citra.bookingCount, 2);
    });

    test('pencarian mencocokkan nama atau email tanpa peduli huruf', () {
      expect(citra.matchesQuery('LESTARI'), isTrue);
      expect(reza.matchesQuery('reza@'), isTrue);
      expect(reza.matchesQuery('citra'), isFalse);
      expect(reza.matchesQuery('   '), isTrue);
    });

    test('filterPawrents menggabungkan filter menginap dan pencarian', () {
      final List<PawrentSummary> all = <PawrentSummary>[citra, reza];
      expect(filterPawrents(all), hasLength(2));
      expect(
        filterPawrents(all, filter: PawrentFilter.staying),
        <PawrentSummary>[citra],
      );
      expect(
        filterPawrents(all, filter: PawrentFilter.staying, query: 'reza'),
        isEmpty,
      );
    });
  });

  group('DTO', () {
    test('ringkasan menghitung kucing dan status dari relasi', () {
      final PawrentSummary summary = pawrentSummaryFromJson(<String, dynamic>{
        'id': 'u1',
        'name': 'Citra',
        'email': 'c@contoh.com',
        'pets': <Object?>[
          <String, dynamic>{'id': 'p1'},
          <String, dynamic>{'id': 'p2'},
        ],
        'bookings': <Object?>[
          <String, dynamic>{'status': 'CheckedIn'},
        ],
      });
      expect(summary.petCount, 2);
      expect(summary.bookingCount, 1);
      expect(summary.isStaying, isTrue);
    });

    test('detail memakai total_price tersimpan dan urut check-in terbaru', () {
      final PawrentDetail detail = pawrentDetailFromJson(<String, dynamic>{
        'id': 'u1',
        'name': 'Citra',
        'email': 'c@contoh.com',
        'created_at': '2024-08-12T03:00:00',
        'pets': <Object?>[
          <String, dynamic>{
            'id': 'p2',
            'pet_name': 'Milo',
            'breed': 'British Shorthair',
            'weight_kg': '4.20',
            'aggressiveness_level': 'Low',
          },
          <String, dynamic>{
            'id': 'p1',
            'pet_name': 'Chiko',
            'breed': 'Scottish Fold',
            'weight_kg': 3.5,
            'aggressiveness_level': null,
          },
        ],
        'bookings': <Object?>[
          <String, dynamic>{
            'id': 'b-old',
            'status': 'CheckedOut',
            'checkin_date': '2024-09-15',
            'checkout_date': '2024-09-18',
            'total_price': '750000.00',
            'pets': <String, dynamic>{'pet_name': 'Milo'},
            'rooms': <String, dynamic>{'room_type': 'Suite'},
          },
          <String, dynamic>{
            'id': 'b-new',
            'status': 'Pending',
            'checkin_date': '2024-10-24',
            'checkout_date': '2024-10-26',
            'total_price': 190000,
            'pets': <String, dynamic>{'pet_name': 'Chiko'},
            'rooms': <String, dynamic>{'room_type': 'Standard'},
          },
        ],
      });

      expect(detail.pets.map((PawrentPet p) => p.name), <String>[
        'Chiko',
        'Milo',
      ]);
      expect(detail.pets.last.weightKg, 4.2);
      expect(detail.bookings.map((PawrentBooking b) => b.id), <String>[
        'b-new',
        'b-old',
      ]);
      expect(detail.bookings.last.totalPrice, 750000);
      expect(detail.bookings.last.roomType, 'Suite');
      expect(detail.isStaying, isFalse);
    });
  });
}
