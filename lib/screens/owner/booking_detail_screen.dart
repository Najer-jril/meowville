import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../widgets/payment_proof_card.dart';
import 'widgets/owner_widgets.dart';

class OwnerBookingDetailScreen extends StatelessWidget {
  const OwnerBookingDetailScreen({super.key, required this.reservation});

  final Reservation reservation;

  Future<void> _upload(BuildContext context) async {
    final r = reservation;
    final store = context.read<AdminStore>();
    final picked = await showUploadProofSheet(
      context,
      amount: r.total,
      current: r.paymentProof,
    );
    if (picked == null) return;
    store.uploadProof(r, picked);
    if (context.mounted) showSnack(context, 'Bukti bayar terkirim');
  }

  Future<void> _cancel(BuildContext context) async {
    final store = context.read<AdminStore>();
    final ok = await showCancelReservationDialog(context, reservation);
    if (!ok) return;
    store.cancel(reservation);
    if (context.mounted) showSnack(context, 'Reservasi dibatalkan');
  }

  void _contactAdmin(BuildContext context) => showSnack(
    context,
    'Membuka WhatsApp admin ${PaymentInfo.adminWhatsApp}...',
  );

  @override
  Widget build(BuildContext context) {
    context.watch<AdminStore>();
    final r = reservation;
    final pending = r.status == ReservationStatus.pending;

    return Scaffold(
      appBar: SubPageAppBar(
        title: 'Detail Reservasi',
        trailing: ownerStatusBadge(r),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          ..._notices(context, r),
          _CatCard(r.cat),
          const SizedBox(height: AppSpacing.lg),
          _StayCard(r),
          const SizedBox(height: AppSpacing.lg),
          CostBreakdownCard(
            type: r.roomType,
            nights: r.nights,
            addons: r.addons,
          ),
          if (pending) ...[
            const SizedBox(height: AppSpacing.lg),
            BankInfoCard(amount: r.total),
          ],
          const SizedBox(height: AppSpacing.lg),
          PaymentProofCard.forReservation(
            r,
            onUpload: pending ? () => _upload(context) : null,
          ),
        ],
      ),
      bottomNavigationBar: _actions(context, r),
    );
  }

  List<Widget> _notices(BuildContext context, Reservation r) {
    final gap = const SizedBox(height: AppSpacing.lg);
    switch (r.status) {
      case ReservationStatus.pending:
        return [
          r.paymentProof == null
              ? ProofDeadlineNotice(r)
              : const NoticeBox(
                  icon: Icons.verified_user_outlined,
                  color: AppColors.info,
                  background: AppColors.infoSoft,
                  message:
                      'Admin sedang memeriksa bukti bayar. Kamu akan '
                      'melihat status Dikonfirmasi setelah disetujui.',
                ),
          gap,
        ];
      case ReservationStatus.rejected:
        return [
          NoticeBox.danger(
            icon: Icons.feedback_outlined,
            title: 'Catatan admin',
            message: r.adminNote ?? 'Reservasi ditolak admin.',
          ),
          if (r.paymentProof != null) ...[
            const SizedBox(height: AppSpacing.md),
            const NoticeBox(
              message: 'Sudah transfer? Hubungi admin untuk pengembalian dana.',
            ),
          ],
          gap,
        ];
      default:
        return const [];
    }
  }

  Widget? _actions(BuildContext context, Reservation r) {
    switch (r.status) {
      case ReservationStatus.pending:
        final cancel = OutlinedButton.icon(
          onPressed: () => _cancel(context),
          style: dangerOutlinedStyle(),
          icon: const Icon(Icons.close),
          label: const Text('Batalkan'),
        );
        return BottomActionBar(
          child: r.paymentProof != null
              ? cancel
              : Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _upload(context),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Unggah Bukti'),
                      ),
                    ),
                  ],
                ),
        );
      case ReservationStatus.confirmed:
        return BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Untuk mengubah atau membatalkan, hubungi admin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _contactAdmin(context),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Hubungi Admin via WhatsApp'),
              ),
            ],
          ),
        );
      case ReservationStatus.checkedIn:
      case ReservationStatus.completed:
        return BottomActionBar(
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.ownerPetReport,
              arguments: r,
            ),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Lihat Laporan Harian'),
          ),
        );
      case ReservationStatus.rejected:
      case ReservationStatus.cancelled:
        return BottomActionBar(
          child: OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.ownerReservationFlow),
            icon: const Icon(Icons.refresh),
            label: const Text('Pesan Kamar Lagi'),
          ),
        );
    }
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard(this.cat);

  final Cat cat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          AppPhoto(cat.photo, size: 72),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: text.titleLarge!.copyWith(fontSize: 20)),
                Text(
                  '${cat.breedLabel} - ${cat.weightLabel}',
                  style: text.bodySmall!.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard(this.r);

  final Reservation r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(
      fontSize: 14,
      color: AppColors.muted,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hotel_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Detail menginap',
                style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoRow('Tipe kamar', r.roomType.name),
          if (r.unit != null)
            InfoRow('Unit', r.unit!)
          else if (r.status == ReservationStatus.pending)
            InfoRow('Unit', 'Ditetapkan saat dikonfirmasi', valueStyle: muted),
          InfoRow('Check-in', Fmt.dateLong(r.checkIn)),
          InfoRow('Check-out', Fmt.dateLong(r.checkOut)),
          InfoRow('Durasi', '${r.nights} malam'),
        ],
      ),
    );
  }
}
