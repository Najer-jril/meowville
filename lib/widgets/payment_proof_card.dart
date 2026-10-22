import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_theme.dart';
import 'app_photo.dart';
import 'common.dart';

class PaymentProofCard extends StatelessWidget {
  const PaymentProofCard({
    super.key,
    required this.proof,
    required this.status,
    required this.tone,
    this.statusIcon = Icons.check_circle_outline,
    this.onUpload,
  });

  factory PaymentProofCard.forReservation(
    Reservation r, {
    Key? key,
    VoidCallback? onUpload,
  }) {
    final proof = r.paymentProof;
    if (proof == null) {
      final waiting = r.status == ReservationStatus.pending;
      return PaymentProofCard(
        key: key,
        proof: null,
        status: waiting ? 'Belum kirim' : 'Tidak ada bukti bayar',
        tone: waiting ? AppColors.warning : AppColors.muted,
        statusIcon: Icons.schedule,
        onUpload: waiting ? onUpload : null,
      );
    }
    return switch (r.status) {
      ReservationStatus.pending => PaymentProofCard(
        key: key,
        proof: proof,
        status: 'Menunggu verifikasi admin',
        tone: AppColors.warning,
        statusIcon: Icons.hourglass_top,
        onUpload: onUpload,
      ),
      ReservationStatus.confirmed ||
      ReservationStatus.checkedIn ||
      ReservationStatus.completed => PaymentProofCard(
        key: key,
        proof: proof,
        status: 'Diterima admin',
        tone: AppColors.success,
      ),
      _ => PaymentProofCard(
        key: key,
        proof: proof,
        status: 'Terkirim',
        tone: AppColors.muted,
      ),
    };
  }

  final String? proof;
  final String status;
  final Color tone;
  final IconData statusIcon;

  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = proof;
    void open() => showPhotoViewer(context, p!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: p == null ? null : open,
                child: AppPhoto(
                  p,
                  size: 64,
                  radius: 14,
                  placeholderIcon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bukti bayar', style: text.titleLarge),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: tone),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            status,
                            style: text.bodySmall!.copyWith(
                              fontSize: 14,
                              color: tone,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (p != null)
                TextButton(onPressed: open, child: const Text('Lihat Bukti')),
            ],
          ),
          if (onUpload != null) ...[
            const SizedBox(height: AppSpacing.md),
            p == null
                ? FilledButton.icon(
                    onPressed: onUpload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Unggah Bukti'),
                  )
                : OutlinedButton.icon(
                    onPressed: onUpload,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Ganti Bukti'),
                  ),
          ],
        ],
      ),
    );
  }
}
