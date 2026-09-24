import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/relative_date.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/owner_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/load_owner_dashboard_usecase.dart';
import '../providers/dashboard_controller.dart';
import '../sections/owner_sections.dart';
import '../widgets/dashboard_bits.dart';
import '../widgets/dashboard_state_panels.dart';
import '../widgets/dashboard_view.dart';

const String _ownerBookings = '/pemilik/reservasi';
const String _ownerReports = '/pemilik/laporan';
const String _ownerPets = '/pemilik/kucing';
const String _ownerRooms = '/pemilik/kamar';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController<OwnerDashboard>>(
      create: (BuildContext context) {
        final Clock clock = context.read<Clock>();
        final LoadOwnerDashboardUseCase load = LoadOwnerDashboardUseCase(
          context.read<DashboardRepository>(),
          clock,
        );
        final AuthUser? user = context.read<AuthNotifier>().user;
        return DashboardController<OwnerDashboard>(() {
          if (user == null) {
            throw const UnauthorizedException(
              'Sesi berakhir. Masuk ulang untuk melanjutkan.',
            );
          }
          return load(userId: user.id);
        });
      },
      child: const _OwnerDashboardView(),
    );
  }
}

class _OwnerDashboardView extends StatelessWidget {
  const _OwnerDashboardView();

  @override
  Widget build(BuildContext context) {
    final Clock clock = context.read<Clock>();
    final String? name = context.watch<AuthNotifier>().user?.name;

    return DashboardView<OwnerDashboard>(
      loadingLabel: 'Memuat kabar anabul Anda...',
      builder: (BuildContext context, OwnerDashboard data) {
        final DateTime now = clock();
        final DateTime today = dateOnly(now);
        void go(String route) => context.go(route);

        return <Widget>[
          DashboardGreeting(
            name: name,
            subtitle: ownerGreetingSubtitle(data, today),
          ),
          const SizedBox(height: 20),
          ..._stay(data, today, go),
          if (data.stayState != OwnerStayState.none) ...<Widget>[
            NewBookingBanner(onTap: () => go(_ownerBookings)),
            const SizedBox(height: 24),
          ],
          if (data.stayState == OwnerStayState.active) ...<Widget>[
            TodayReportsSection(
              logs: data.todayLogs,
              now: now,
              onOpenAll: () => go(_ownerReports),
            ),
            const SizedBox(height: 24),
          ],
          PetsSection(
            pets: data.pets,
            stayingPetIds: data.stayingPetIds,
            onOpenPets: () => go(_ownerPets),
          ),
          const SizedBox(height: 24),
          BookingHistorySection(
            history: data.history,
            onOpenAll: () => go(_ownerBookings),
          ),
          const SizedBox(height: 24),
          RoomTiersSection(
            rooms: data.rooms,
            onOpenRooms: () => go(_ownerRooms),
          ),
        ];
      },
    );
  }

  List<Widget> _stay(
    OwnerDashboard data,
    DateTime today,
    void Function(String route) go,
  ) {
    switch (data.stayState) {
      case OwnerStayState.active:
        return <Widget>[
          ActiveStayHero(
            booking: data.active!,
            today: today,
            onOpenReports: () => go(_ownerReports),
            onOpenBooking: () => go(_ownerBookings),
          ),
          const SizedBox(height: 16),
        ];
      case OwnerStayState.upcoming:
        return <Widget>[
          for (final booking in data.upcoming.take(3)) ...<Widget>[
            UpcomingStayCard(
              booking: booking,
              today: today,
              onTap: () => go(_ownerBookings),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
        ];
      case OwnerStayState.none:
        return <Widget>[
          DashboardEmptyPanel(
            icon: Icons.home_rounded,
            title: 'Kamar masih menunggu anabul',
            message:
                'Belum ada reservasi. Pilih tanggal dan tipe kamar untuk '
                'kucing Anda.',
            actionLabel: 'Pilih Tanggal Menginap',
            onAction: () => go(_ownerBookings),
          ),
          const SizedBox(height: 24),
        ];
    }
  }
}
