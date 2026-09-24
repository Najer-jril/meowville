import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

import '../../auth/domain/entities/user_role.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
    required this.placeholderSummary,
    this.isPrimaryAction = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final String placeholderSummary;
  final bool isPrimaryAction;
}

abstract final class RoleNavigation {
  static const List<NavDestination> owner = <NavDestination>[
    NavDestination(
      label: 'Beranda',
      icon: Icons.home_outlined,
      route: '/pemilik',
      placeholderSummary: 'Ringkasan kabar anabul dan reservasi Anda.',
    ),
    NavDestination(
      label: 'Kamar',
      icon: Icons.bed_outlined,
      route: '/pemilik/kamar',
      placeholderSummary: 'Pilih tipe kamar dan tanggal menginap.',
    ),
    NavDestination(
      label: 'Reservasi',
      icon: Icons.event_note_outlined,
      route: '/pemilik/reservasi',
      placeholderSummary: 'Buat reservasi baru dan lihat semua reservasi Anda.',
    ),
    NavDestination(
      label: 'Laporan',
      icon: Icons.article_outlined,
      route: '/pemilik/laporan',
      placeholderSummary:
          'Baca kabar harian dari penjaga untuk kucing yang sedang menginap.',
    ),
    NavDestination(
      label: 'Kucingku',
      icon: Icons.pets_outlined,
      route: '/pemilik/kucing',
      placeholderSummary: 'Lihat dan ubah data kucing yang Anda titipkan.',
    ),
  ];

  static const List<NavDestination> sitter = <NavDestination>[
    NavDestination(
      label: 'Tugas',
      icon: Icons.checklist_rounded,
      route: '/penjaga',
      placeholderSummary: 'Kucing yang jadi tanggung jawab Anda hari ini.',
    ),
    NavDestination(
      label: 'Tamu',
      icon: Icons.groups_outlined,
      route: '/penjaga/tamu',
      placeholderSummary: 'Daftar tamu yang ditugaskan kepada Anda.',
    ),
    NavDestination(
      label: 'Catat',
      icon: Icons.edit_note_rounded,
      route: '/penjaga/catat',
      placeholderSummary: 'Tulis laporan harian untuk kucing yang menginap.',
      isPrimaryAction: true,
    ),
    NavDestination(
      label: 'Riwayat',
      icon: Icons.history_rounded,
      route: '/penjaga/riwayat',
      placeholderSummary: 'Laporan yang sudah Anda tulis sebelumnya.',
    ),
    NavDestination(
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      route: '/penjaga/profil',
      placeholderSummary: 'Data akun Anda sebagai penjaga.',
    ),
  ];

  static const List<NavDestination> admin = <NavDestination>[
    NavDestination(
      label: 'Dashboard',
      icon: Icons.space_dashboard_outlined,
      route: '/admin',
      placeholderSummary: 'Keputusan yang menunggu dan kapasitas hari ini.',
    ),
    NavDestination(
      label: 'Reservasi',
      icon: Icons.event_note_outlined,
      route: '/admin/reservasi',
      placeholderSummary: 'Semua reservasi, dari yang menunggu sampai selesai.',
    ),
    NavDestination(
      label: 'Kamar',
      icon: Icons.bed_outlined,
      route: '/admin/kamar',
      placeholderSummary: 'Kelola unit kamar, tarif, dan penutupan kamar.',
    ),
    NavDestination(
      label: 'Pawrent',
      icon: Icons.people_outline_rounded,
      route: '/admin/pawrent',
      placeholderSummary: 'Daftar pemilik kucing beserta kucingnya.',
    ),
    NavDestination(
      label: 'Kelola',
      icon: Icons.tune_rounded,
      route: '/admin/kelola',
      placeholderSummary: 'Kelola akun penjaga dan penugasannya.',
    ),
  ];

  static const List<NavDestination> adminExtras = <NavDestination>[
    NavDestination(
      label: 'Laporan',
      icon: Icons.article_outlined,
      route: '/admin/laporan',
      placeholderSummary: 'Laporan harian dari semua penjaga.',
    ),
  ];

  static List<NavDestination> forRole(UserRole role) => switch (role) {
    UserRole.petOwner => owner,
    UserRole.petSitter => sitter,
    UserRole.admin => admin,
  };

  static int indexFor(List<NavDestination> destinations, String location) {
    int best = -1;
    int bestLength = -1;
    for (int i = 0; i < destinations.length; i++) {
      final String route = destinations[i].route;
      final bool matches = location == route || location.startsWith('$route/');
      if (matches && route.length > bestLength) {
        best = i;
        bestLength = route.length;
      }
    }
    return best;
  }
}
