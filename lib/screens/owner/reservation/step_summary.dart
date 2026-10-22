import 'package:flutter/material.dart';

import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/app_photo.dart';
import '../../../widgets/common.dart';
import '../../../widgets/payment_proof_card.dart';
import '../widgets/owner_widgets.dart';

class StepSummary extends StatelessWidget {
  const StepSummary({
    super.key,
    required this.cat,
    required this.type,
    required this.range,
    required this.addons,
    required this.proof,
    required this.onProofChanged,
  });

  final Cat cat;
  final RoomType type;
  final DateTimeRange range;
  final List<Addon> addons;
  final String? proof;
  final ValueChanged<String> onProofChanged;

  int get _nights => range.duration.inDays;
  int get _total =>
      type.price * _nights + addons.fold(0, (s, a) => s + a.price);

  Future<void> _upload(BuildContext context) async {
    final picked = await showUploadProofSheet(
      context,
      amount: _total,
      current: proof,
    );
    if (picked != null) onProofChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  AppPhoto(cat.photo, size: 56, radius: 14),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name, style: text.titleLarge),
                        Text(
                          '${cat.breedLabel} - ${cat.weightLabel}',
                          style: text.bodySmall!.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Column(
                  children: [
                    InfoRow('Kamar', type.name),
                    InfoRow('Check-in', Fmt.dateLong(range.start)),
                    InfoRow('Check-out', Fmt.dateLong(range.end)),
                    InfoRow('Durasi', '$_nights malam'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CostBreakdownCard(type: type, nights: _nights, addons: addons),
        const SizedBox(height: AppSpacing.lg),
        BankInfoCard(amount: _total),
        const SizedBox(height: AppSpacing.lg),
        if (proof == null) ...[
          PaymentProofCard(
            proof: null,
            status: 'Opsional, bisa diunggah nanti',
            tone: AppColors.muted,
            statusIcon: Icons.info_outline,
            onUpload: () => _upload(context),
          ),
          const SizedBox(height: AppSpacing.md),
          const NoticeBox(
            message:
                'Tanpa bukti bayar, kamar ditahan maksimal 24 jam. '
                'Admin baru bisa menyetujui setelah bukti diunggah.',
          ),
        ] else
          PaymentProofCard(
            proof: proof,
            status: 'Siap dikirim',
            tone: AppColors.success,
            onUpload: () => _upload(context),
          ),
      ],
    );
  }
}
