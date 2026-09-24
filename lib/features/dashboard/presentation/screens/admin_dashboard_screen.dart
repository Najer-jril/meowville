import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/clock.dart';
import '../../../admin_manage/presentation/admin_manage_routes.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/create_payment_proof_url_usecase.dart';
import '../../domain/usecases/load_admin_dashboard_usecase.dart';
import '../providers/dashboard_controller.dart';
import '../sections/admin_sections.dart';
import '../widgets/dashboard_bits.dart';
import '../widgets/dashboard_view.dart';
import '../widgets/filter_segmented_tabs.dart';

const String _adminBookings = '/admin/reservasi';
const String _adminRooms = '/admin/kamar';
const String _adminOwners = '/admin/pawrent';
const String _adminReports = '/admin/laporan';
const String _adminManage = AdminManageRoutes.staff;

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController<AdminDashboard>>(
      create: (BuildContext context) {
        final LoadAdminDashboardUseCase load = LoadAdminDashboardUseCase(
          context.read<DashboardRepository>(),
          context.read<Clock>(),
        );
        return DashboardController<AdminDashboard>(load.call);
      },
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  Future<void> _openProof(BuildContext context, BookingSummary booking) {
    final CreatePaymentProofUrlUseCase createUrl = CreatePaymentProofUrlUseCase(
      context.read<DashboardRepository>(),
    );
    final Future<String> url = createUrl(booking.paymentProofPath!);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) =>
          _ProofDialog(title: booking.pet.name, url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Clock clock = context.read<Clock>();
    final String? name = context.watch<AuthNotifier>().user?.name;

    return DashboardView<AdminDashboard>(
      loadingLabel: 'Memuat ringkasan hari ini...',
      skeletonHeights: const <double>[160, 120, 160],
      builder: (BuildContext context, AdminDashboard data) {
        return <Widget>[
          DashboardGreeting(name: name, subtitle: adminGreetingSubtitle(data)),
          const SizedBox(height: 20),
          _AdminBody(
            data: data,
            now: clock(),
            onOpenProof: (BookingSummary b) => _openProof(context, b),
            onGo: context.go,
          ),
        ];
      },
    );
  }
}

class _AdminBody extends StatefulWidget {
  const _AdminBody({
    required this.data,
    required this.now,
    required this.onOpenProof,
    required this.onGo,
  });

  final AdminDashboard data;
  final DateTime now;
  final ValueChanged<BookingSummary> onOpenProof;
  final void Function(String route) onGo;

  @override
  State<_AdminBody> createState() => _AdminBodyState();
}

class _AdminBodyState extends State<_AdminBody> {
  static const int _all = 0;
  static const int _today = 1;
  static const int _needsResponse = 2;

  int _filter = _all;

  @override
  Widget build(BuildContext context) {
    final AdminDashboard data = widget.data;
    final bool showPending = _filter != _today;
    final bool showToday = _filter != _needsResponse;
    final bool showRecent = _filter == _all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilterSegmentedTabs(
          options: <FilterTabOption>[
            const FilterTabOption(label: 'Semua'),
            const FilterTabOption(label: 'Hari Ini'),
            FilterTabOption(label: 'Perlu Respon', count: data.pendingCount),
          ],
          selectedIndex: _filter,
          onSelected: (int index) => setState(() => _filter = index),
        ),
        const SizedBox(height: AppSpacing.space24),
        if (showPending) ...<Widget>[
          PendingBookingsSection(
            data: data,
            now: widget.now,
            onOpenProof: widget.onOpenProof,
          ),
          const SizedBox(height: AppSpacing.space24),
        ],
        if (showToday) ...<Widget>[
          AdminSummaryGrid(data: data),
          const SizedBox(height: AppSpacing.space24),
          OccupancySection(occupancy: data.occupancy),
          const SizedBox(height: AppSpacing.space24),
        ],
        MissingReportsSection(
          missing: data.missingReports,
          stayingCount: data.stayingCount,
          onOpenSitters: () => widget.onGo(_adminManage),
        ),
        const SizedBox(height: AppSpacing.space24),
        if (showToday) ...<Widget>[
          QuickActionGrid(
            pendingCount: data.pendingCount,
            onOpenBookings: () => widget.onGo(_adminBookings),
            onOpenRooms: () => widget.onGo(_adminRooms),
            onOpenOwners: () => widget.onGo(_adminOwners),
            onOpenReports: () => widget.onGo(_adminReports),
          ),
          const SizedBox(height: AppSpacing.space24),
        ],
        if (showRecent)
          RecentBookingsSection(
            data: data,
            onOpenAll: () => widget.onGo(_adminBookings),
          ),
      ],
    );
  }
}

class _ProofDialog extends StatelessWidget {
  const _ProofDialog({required this.title, required this.url});

  final String title;
  final Future<String> url;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Bukti bayar $title', style: AppTypography.headlineSm),
            const SizedBox(height: AppSpacing.space12),
            FutureBuilder<String>(
              future: url,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Bukti belum bisa dibuka. Tutup, lalu coba lagi.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onErrorContainer,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Text(
                    'Memuat bukti bayar...',
                    style: AppTypography.bodyMd,
                  );
                }
                return ClipRRect(
                  borderRadius: AppRadius.controlAll,
                  child: InteractiveViewer(
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? trace,
                          ) => Text(
                            'Gambar bukti tidak bisa ditampilkan.',
                            style: AppTypography.bodyMd,
                          ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.space12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandTerracottaDark,
                  textStyle: AppTypography.labelLg,
                  minimumSize: const Size(
                    AppSpacing.minTapTarget,
                    AppSpacing.minTapTarget,
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
