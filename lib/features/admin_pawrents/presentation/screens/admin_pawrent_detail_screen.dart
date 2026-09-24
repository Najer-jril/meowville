import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_back_link.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_state_panels.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../domain/entities/pawrent.dart';
import '../../domain/repositories/admin_pawrent_repository.dart';
import '../../domain/usecases/load_pawrents_usecase.dart';
import '../admin_pawrent_routes.dart';
import '../widgets/pawrent_widgets.dart';

typedef PawrentDetailController = DashboardController<PawrentDetail>;

class AdminPawrentDetailScreen extends StatelessWidget {
  const AdminPawrentDetailScreen({super.key, required this.ownerId});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    final AdminPawrentRepository repository = context
        .read<AdminPawrentRepository>();

    return ChangeNotifierProvider<PawrentDetailController>(
      create: (_) => PawrentDetailController(
        () => LoadPawrentDetailUseCase(repository)(ownerId),
        fallbackMessage:
            'Data pawrent gagal dimuat. Coba ulangi sebentar lagi.',
      ),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminPawrentRoutes.list);
    }
  }

  Future<void> _openBooking(
    BuildContext context,
    PawrentDetail pawrent,
    PawrentBooking booking,
  ) async {
    final PawrentDetailController controller = context
        .read<PawrentDetailController>();
    await context.push(AdminPawrentRoutes.booking(pawrent.id, booking.id));
    // Admin bisa menyetujui atau membatalkan di sana; tampilkan status baru.
    await controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBackLink(label: 'Daftar pawrent', onBack: () => _back(context)),
        Expanded(
          child: DashboardView<PawrentDetail>(
            loadingLabel: 'Memuat data pawrent...',
            errorTitle: 'Data pawrent belum bisa dimuat',
            skeletonHeights: const <double>[88, 32, 72, 72, 32, 108, 108],
            builder: (BuildContext context, PawrentDetail pawrent) => <Widget>[
              PawrentHeader(pawrent: pawrent),
              const SizedBox(height: AppSpacing.space32),
              PawrentSectionTitle(text: 'Kucing (${pawrent.pets.length})'),
              const SizedBox(height: AppSpacing.space12),
              if (pawrent.pets.isEmpty)
                const DashboardEmptyPanel(
                  icon: Icons.pets_rounded,
                  title: 'Belum ada kucing terdaftar',
                  message:
                      'Pawrent ini belum menambahkan profil kucing di '
                      'aplikasinya.',
                  compact: true,
                )
              else
                for (int i = 0; i < pawrent.pets.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.space8),
                  PawrentPetTile(pet: pawrent.pets[i]),
                ],
              const SizedBox(height: AppSpacing.space32),
              PawrentSectionTitle(
                text: 'Riwayat reservasi (${pawrent.bookings.length})',
              ),
              const SizedBox(height: AppSpacing.space12),
              if (pawrent.bookings.isEmpty)
                const DashboardEmptyPanel(
                  icon: Icons.event_busy_rounded,
                  title: 'Belum ada reservasi',
                  message: 'Reservasi yang dibuat pawrent ini akan tercatat di sini.',
                )
              else
                for (int i = 0; i < pawrent.bookings.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.space12),
                  PawrentBookingCard(
                    booking: pawrent.bookings[i],
                    onTap: () =>
                        _openBooking(context, pawrent, pawrent.bookings[i]),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
