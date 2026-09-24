import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/clock.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/entities/sitter_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/load_sitter_dashboard_usecase.dart';
import '../providers/dashboard_controller.dart';
import '../sections/sitter_sections.dart';
import '../widgets/dashboard_bits.dart';
import '../widgets/dashboard_view.dart';

const String _sitterRecord = '/penjaga/catat';
const String _sitterHistory = '/penjaga/riwayat';

class SitterDashboardScreen extends StatelessWidget {
  const SitterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController<SitterDashboard>>(
      create: (BuildContext context) {
        final LoadSitterDashboardUseCase load = LoadSitterDashboardUseCase(
          context.read<DashboardRepository>(),
          context.read<Clock>(),
        );
        final AuthUser? user = context.read<AuthNotifier>().user;
        return DashboardController<SitterDashboard>(() {
          if (user == null) {
            throw const UnauthorizedException(
              'Sesi berakhir. Masuk ulang untuk melanjutkan.',
            );
          }
          return load(sitterId: user.id);
        });
      },
      child: const _SitterDashboardView(),
    );
  }
}

class _SitterDashboardView extends StatelessWidget {
  const _SitterDashboardView();

  static String _recordRoute(BookingSummary booking) => Uri(
    path: _sitterRecord,
    queryParameters: <String, String>{'booking': booking.id},
  ).toString();

  static String _historyRoute(BookingSummary booking) => Uri(
    path: _sitterHistory,
    queryParameters: <String, String>{'booking': booking.id},
  ).toString();

  @override
  Widget build(BuildContext context) {
    final String? name = context.watch<AuthNotifier>().user?.name;

    return DashboardView<SitterDashboard>(
      loadingLabel: 'Memuat tugas hari ini...',
      skeletonHeights: const <double>[120, 120, 148],
      builder: (BuildContext context, SitterDashboard data) {
        void go(String route) => context.go(route);

        return <Widget>[
          DashboardGreeting(name: name, subtitle: sitterGreetingSubtitle(data)),
          const SizedBox(height: 20),
          SitterSummaryGrid(data: data),
          const SizedBox(height: 24),
          if (data.stayingCount > 0) ...<Widget>[
            RecordReportCard(
              pending: data.pendingReportGuests,
              onRecord: () => go(_sitterRecord),
              onRecordFor: (BookingSummary b) => go(_recordRoute(b)),
            ),
            const SizedBox(height: 24),
          ],
          SitterTasksSection(
            data: data,
            onRecordFor: (BookingSummary b) => go(_recordRoute(b)),
          ),
          const SizedBox(height: 24),
          StayingGuestsSection(
            data: data,
            onRecordFor: (BookingSummary b) => go(_recordRoute(b)),
            onOpenLog: (BookingSummary b) => go(_historyRoute(b)),
          ),
        ];
      },
    );
  }
}
