import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_back_link.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../domain/entities/admin_booking.dart';
import '../../domain/entities/booking_decision.dart';
import '../../domain/repositories/admin_booking_repository.dart';
import '../../domain/usecases/decide_booking_usecase.dart';
import '../../domain/usecases/load_admin_bookings_usecase.dart';
import '../admin_booking_routes.dart';
import '../providers/booking_decision_controller.dart';
import '../widgets/booking_decision_dialog.dart';
import '../widgets/booking_detail_sections.dart';

typedef AdminBookingDetailController = DashboardController<AdminBooking>;

class AdminBookingDetailScreen extends StatelessWidget {
  const AdminBookingDetailScreen({
    super.key,
    required this.bookingId,
    this.backLabel = 'Daftar reservasi',
    this.backRoute = AdminBookingRoutes.list,
  });

  final String bookingId;

  final String backLabel;
  final String backRoute;

  @override
  Widget build(BuildContext context) {
    final AdminBookingRepository repository = context
        .read<AdminBookingRepository>();

    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AdminBookingDetailController>(
          create: (_) => AdminBookingDetailController(
            () => LoadAdminBookingDetailUseCase(repository)(bookingId),
            fallbackMessage:
                'Detail reservasi gagal dimuat. Coba ulangi sebentar lagi.',
          ),
        ),
        ChangeNotifierProvider<BookingDecisionController>(
          create: (BuildContext context) => BookingDecisionController(
            DecideBookingUseCase(repository),
            () => context.read<AuthNotifier>().user?.id,
          ),
        ),
      ],
      child: _DetailView(backLabel: backLabel, backRoute: backRoute),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.backLabel, required this.backRoute});

  final String backLabel;
  final String backRoute;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(backRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AdminBookingDetailController controller = context
        .watch<AdminBookingDetailController>();
    final AdminBooking? booking = controller.status == DashboardStatus.ready
        ? controller.data
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppBackLink(label: backLabel, onBack: () => _back(context)),
        Expanded(
          child: DashboardView<AdminBooking>(
            loadingLabel: 'Memuat detail reservasi...',
            errorTitle: 'Detail reservasi belum bisa dimuat',
            skeletonHeights: const <double>[56, 160, 120, 200, 140],
            builder: (BuildContext context, AdminBooking booking) => <Widget>[
              BookingSummaryHeader(booking: booking),
              const SizedBox(height: AppSpacing.space20),
              PetDetailCard(booking: booking),
              const SizedBox(height: AppSpacing.space12),
              OwnerDetailCard(booking: booking),
              const SizedBox(height: AppSpacing.space12),
              StayDetailCard(booking: booking),
              const SizedBox(height: AppSpacing.space12),
              AddOnDetailCard(booking: booking),
              const SizedBox(height: AppSpacing.space12),
              CostDetailCard(booking: booking),
            ],
          ),
        ),
        if (booking != null && booking.decisions.isNotEmpty)
          _ActionBar(booking: booking),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.booking});

  final AdminBooking booking;

  Future<void> _decide(BuildContext context, BookingDecision decision) async {
    final BookingDecisionController decisions = context
        .read<BookingDecisionController>();
    final AdminBookingDetailController detail = context
        .read<AdminBookingDetailController>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool confirmed = await confirmBookingDecision(
      context,
      booking: booking,
      decision: decision,
    );
    if (!confirmed) {
      return;
    }

    final bool saved = await decisions.submit(booking, decision);
    await detail.refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? decisionDoneMessage(decision, booking.petName)
              : decisions.errorMessage ??
                    'Keputusan belum tersimpan. Coba ulangi sebentar lagi.',
        ),
        duration: Duration(seconds: saved ? 4 : 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BookingDecisionController decisions = context
        .watch<BookingDecisionController>();
    final List<BookingDecision> available = booking.decisions;

    Widget buttonFor(BookingDecision decision) {
      final bool loading = decisions.inFlight == decision;
      final VoidCallback? onPressed = decisions.isSubmitting
          ? null
          : () => _decide(context, decision);
      if (decision == BookingDecision.approve) {
        return AppPrimaryButton(
          label: decisionLabel(decision),
          leadingIcon: Icons.check_rounded,
          isLoading: loading,
          onPressed: onPressed,
        );
      }
      return AppSecondaryButton(
        label: decisionLabel(decision),
        leadingIcon: Icons.close_rounded,
        isLoading: loading,
        onPressed: onPressed,
      );
    }

    final List<BookingDecision> ordered = <BookingDecision>[
      ...available.where((BookingDecision d) => d != BookingDecision.approve),
      ...available.where((BookingDecision d) => d == BookingDecision.approve),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.space12,
          AppSpacing.screenEdge,
          AppSpacing.space12,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (int i = 0; i < ordered.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: AppSpacing.space12),
                      Expanded(child: buttonFor(ordered[i])),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
