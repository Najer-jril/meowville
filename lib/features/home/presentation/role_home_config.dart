import 'package:flutter/painting.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/domain/entities/user_role.dart';

class RoleHomeConfig {
  const RoleHomeConfig({
    required this.role,
    required this.route,
    required this.roleLabel,
    required this.intent,
    required this.accentSurface,
    required this.accentText,
    required this.upcoming,
  });

  final UserRole role;
  final String route;
  final String roleLabel;
  final String intent;
  final Color accentSurface;
  final Color accentText;
  final List<UpcomingArea> upcoming;

  static const String ownerRoute = '/pemilik';
  static const String sitterRoute = '/penjaga';
  static const String adminRoute = '/admin';

  static const RoleHomeConfig owner = RoleHomeConfig(
    role: UserRole.petOwner,
    route: ownerRoute,
    roleLabel: 'Akun pemilik',
    intent:
        'Beranda pemilik akan menjadi tempat Anda memesan kamar, membaca '
        'kabar harian anabul, dan menyimpan data kucing Anda.',
    accentSurface: AppColors.badgeStayingSurface,
    accentText: AppColors.badgeStayingText,
    upcoming: <UpcomingArea>[
      UpcomingArea(
        title: 'Pesan kamar penitipan',
        summary: 'Pilih tanggal, kamar, dan jumlah kucing yang dititipkan.',
      ),
      UpcomingArea(
        title: 'Kabar harian anabul',
        summary: 'Catatan makan, main, dan foto dari penjaga yang bertugas.',
      ),
      UpcomingArea(
        title: 'Riwayat reservasi',
        summary: 'Daftar kunjungan sebelumnya beserta status pembayarannya.',
      ),
    ],
  );

  static const RoleHomeConfig sitter = RoleHomeConfig(
    role: UserRole.petSitter,
    route: sitterRoute,
    roleLabel: 'Akun penjaga',
    intent:
        'Beranda penjaga akan menjadi tempat Anda menerima jadwal titipan, '
        'mencatat perawatan harian, dan mengirim kabar ke pemilik.',
    accentSurface: AppColors.successSurface,
    accentText: AppColors.successText,
    upcoming: <UpcomingArea>[
      UpcomingArea(
        title: 'Jadwal titipan hari ini',
        summary: 'Kucing yang menginap, kamarnya, dan jam perawatannya.',
      ),
      UpcomingArea(
        title: 'Catatan perawatan',
        summary: 'Isian makan, kebersihan kandang, dan kondisi kucing.',
      ),
      UpcomingArea(
        title: 'Kirim kabar ke pemilik',
        summary: 'Foto dan catatan singkat yang dibaca pemilik di berandanya.',
      ),
    ],
  );

  static const RoleHomeConfig admin = RoleHomeConfig(
    role: UserRole.admin,
    route: adminRoute,
    roleLabel: 'Akun admin',
    intent:
        'Beranda admin akan menjadi tempat Anda memverifikasi reservasi, '
        'mengatur kamar dan tarif, serta mengelola akun penjaga.',
    accentSurface: AppColors.infoSurface,
    accentText: AppColors.infoText,
    upcoming: <UpcomingArea>[
      UpcomingArea(
        title: 'Verifikasi reservasi',
        summary: 'Setujui atau tolak permintaan titipan yang masuk.',
      ),
      UpcomingArea(
        title: 'Kelola kamar dan tarif',
        summary: 'Jumlah kamar, kapasitas, dan harga per malam.',
      ),
      UpcomingArea(
        title: 'Kelola akun penjaga',
        summary: 'Tinjau penjaga yang mendaftar dan atur aksesnya.',
      ),
    ],
  );

  static const List<RoleHomeConfig> all = <RoleHomeConfig>[
    owner,
    sitter,
    admin,
  ];

  static RoleHomeConfig forRole(UserRole role) => switch (role) {
    UserRole.petOwner => owner,
    UserRole.petSitter => sitter,
    UserRole.admin => admin,
  };

  static bool isRoleRoute(String location) =>
      all.any((RoleHomeConfig config) => config.route == location);
}

class UpcomingArea {
  const UpcomingArea({required this.title, required this.summary});

  final String title;
  final String summary;
}
