import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';
import '../../widgets/payment_proof_card.dart';
import 'widgets/reservation_actions.dart';

class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    context.watch<AdminStore>();

    final r = reservation;

    return Scaffold(
      appBar: SubPageAppBar(
        title: 'Detail Reservasi',
        trailing: StatusBadge.booking(r.status.key),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          _CatCard(r),
          const SizedBox(height: AppSpacing.lg),
          _OwnerCard(r),
          const SizedBox(height: AppSpacing.lg),
          _StayCard(r),
          const SizedBox(height: AppSpacing.lg),
          _CostCard(r),
          const SizedBox(height: AppSpacing.lg),
          PaymentProofCard.forReservation(r),
          if (r.adminNote != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _NoteCard(r.adminNote!),
          ],
        ],
      ),
      bottomNavigationBar: _actions(context, r),
    );
  }

  Widget? _actions(BuildContext context, Reservation r) {
    switch (r.status) {
      case ReservationStatus.pending:
        final hasProof = r.paymentProof != null;
        return BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasProof)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Setujui setelah pemilik mengunggah bukti bayar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => showRejectSheet(context, r),
                      style: dangerOutlinedStyle(),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: hasProof
                          ? () => showApproveSheet(context, r)
                          : null,
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case ReservationStatus.confirmed:
        return BottomActionBar(
          child: OutlinedButton(
            onPressed: () async {
              final store = context.read<AdminStore>();
              final ok = await showConfirmDialog(
                context,
                title: 'Batalkan reservasi?',
                message:
                    'Unit ${r.unit} akan tersedia lagi untuk '
                    '${Fmt.range(r.checkIn, r.checkOut)}. Pemilik akan '
                    'melihat status Dibatalkan.',
                confirmLabel: 'Batalkan',
                destructive: true,
                icon: Icons.event_busy,
              );
              if (ok) {
                store.cancel(r);
                if (context.mounted) showSnack(context, 'Reservasi dibatalkan');
              }
            },
            style: dangerOutlinedStyle(),
            child: const Text('Batalkan Reservasi'),
          ),
        );
      default:
        return null;
    }
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard(this.r);

  final Reservation r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          AppPhoto(r.cat.photo, size: 72),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.cat.name,
                  style: text.titleLarge!.copyWith(fontSize: 20),
                ),
                Text(
                  '${r.cat.breedLabel} - ${r.cat.weightLabel}',
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

class _OwnerCard extends StatelessWidget {
  const _OwnerCard(this.r);

  final Reservation r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Owner', style: text.labelSmall!.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: AppSpacing.xs),
          Text(r.owner.name, style: text.titleLarge),
          Text(r.owner.phone, style: text.bodySmall!.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.icon, this.title);

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge!
                .copyWith(fontWeight: FontWeight.w700),
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
    final muted = Theme.of(context).textTheme.bodyMedium!
        .copyWith(fontSize: 14, color: AppColors.muted);
    return AppCard(
      child: Column(
        children: [
          const _CardTitle(Icons.hotel_outlined, 'Detail Menginap'),
          InfoRow('Tipe Kamar', 'Kamar ${r.roomType.name}'),
          if (r.unit != null)
            InfoRow('Unit', r.unit!)
          else if (r.status == ReservationStatus.pending)
            InfoRow('Unit', 'Dipilih saat disetujui', valueStyle: muted),
          InfoRow('Check-in', Fmt.dateLong(r.checkIn)),
          InfoRow('Check-out', Fmt.dateLong(r.checkOut)),
          InfoRow('Durasi', '${r.nights} malam'),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard(this.r);

  final Reservation r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget line(String label, int value, {String? sub}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodyLarge),
                if (sub != null) Text(sub, style: text.bodySmall),
              ],
            ),
          ),
          Text(Fmt.rupiah(value), style: text.bodyLarge),
        ],
      ),
    );

    return AppCard(
      child: Column(
        children: [
          const _CardTitle(Icons.receipt_long_outlined, 'Rincian Biaya'),
          line(
            'Kamar ${r.roomType.name} x ${r.nights} malam',
            r.roomTotal,
            sub: '${Fmt.rupiah(r.roomType.price)}/malam',
          ),
          for (final a in r.addons) line(a.name, a.price),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(child: Text('Total', style: text.labelLarge)),
              Text(
                Fmt.rupiah(r.total),
                style: text.titleLarge!.copyWith(
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard(this.note);

  final String note;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan admin',
            style: text.labelLarge!.copyWith(color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(note, style: text.bodyLarge),
        ],
      ),
    );
  }
}
