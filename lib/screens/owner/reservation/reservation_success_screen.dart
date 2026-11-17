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
                        const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.xl),
                          child: IconBubble(
                            icon: Icons.check_rounded,
                            color: AppColors.success,
                            background: AppColors.successSoft,
                            size: 96,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            'Reservasi terkirim',
                            textAlign: TextAlign.center,
                            style: text.headlineLarge!.copyWith(fontSize: 30),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Text(
                            'Reservasi ${r.cat.name} menunggu konfirmasi admin.',
                            textAlign: TextAlign.center,
                            style: text.bodyLarge!.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        AppCard(
                          child: Row(
                            spacing: AppSpacing.md,
                            children: [
                              AppPhoto(r.cat.photo, size: 56, radius: 14),
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
                        if (r.paymentProof == null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: ProofDeadlineNotice(r),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xl,
                            bottom: AppSpacing.xs,
                          ),
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.ownerBookingDetail,
                              arguments: r,
                            ),
                            icon: const Icon(Icons.arrow_forward),
                            iconAlignment: IconAlignment.end,
                            label: const Text('Lihat Reservasi'),
                          ),
                        ),
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
              SvgPicture.asset(
                AppSvg.villageCat,
                width: double.infinity,
                height: AppSizes.artLg,
                fit: BoxFit.fill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
