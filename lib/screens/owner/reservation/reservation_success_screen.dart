import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models.dart';
import '../../../theme/app_assets.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/app_photo.dart';
import '../../../widgets/common.dart';
import '../widgets/owner_widgets.dart';

class ReservationSuccessScreen extends StatelessWidget {
  const ReservationSuccessScreen({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.popUntil(context, (route) => route.isFirst);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    child: Column(
                      children: [
                        const IconBubble(
                          icon: Icons.check_rounded,
                          color: AppColors.success,
                          background: AppColors.successSoft,
                          size: 96,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Reservasi terkirim',
                          textAlign: TextAlign.center,
                          style: text.headlineLarge!.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Reservasi ${r.cat.name} menunggu konfirmasi admin.',
                          textAlign: TextAlign.center,
                          style: text.bodyLarge!.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppCard(
                          child: Row(
                            children: [
                              AppPhoto(r.cat.photo, size: 56, radius: 14),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.cat.name, style: text.titleLarge),
                                    Text(
                                      'Kamar ${r.roomType.name} - '
                                      '${Fmt.range(r.checkIn, r.checkOut)} - '
                                      '${r.nights} malam',
                                      style: text.bodySmall!.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (r.paymentProof == null) ...[
                          const SizedBox(height: AppSpacing.md),
                          ProofDeadlineNotice(r),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.ownerBookingDetail,
                            arguments: r,
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          iconAlignment: IconAlignment.end,
                          label: const Text('Lihat Reservasi'),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextButton(
                          onPressed: () => Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          ),
                          child: const Text('Kembali ke Beranda'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: SvgPicture.asset(AppSvg.villageCat, fit: BoxFit.fill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
