import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../services/storage_service.dart';
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
    final p = proof;
    if (!isPrivatePhoto(p)) return _card(context, p, hasProof: p != null);
    return _SignedProof(
      path: p!,
      builder: (url) => _card(context, url, hasProof: true),
    );
  }

  /// [p] adalah foto yang bisa ditampilkan, null selama signed URL
  /// masih dimuat.
  Widget _card(BuildContext context, String? p, {required bool hasProof}) {
    final text = Theme.of(context).textTheme;
    void open() => showPhotoViewer(context, p!);

    return AppCard(
      child: Column(
        spacing: AppSpacing.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: GestureDetector(
                  onTap: p == null ? null : open,
                  child: AppPhoto(
                    p,
                    size: 64,
                    radius: 14,
                    placeholderIcon: Icons.receipt_long_outlined,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bukti bayar', style: text.titleLarge),
                    Row(
                      spacing: AppSpacing.xs,
                      children: [
                        Icon(statusIcon, size: 16, color: tone),
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
              if (hasProof)
                TextButton(
                  onPressed: p == null ? null : open,
                  child: const Text('Lihat Bukti'),
                ),
            ],
          ),
          if (onUpload != null)
            !hasProof
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
      ),
    );
  }
}

/// Mengambil signed URL untuk bukti bayar privat, sekali per path.
class _SignedProof extends StatefulWidget {
  const _SignedProof({required this.path, required this.builder});

  final String path;
  final Widget Function(String? url) builder;

  @override
  State<_SignedProof> createState() => _SignedProofState();
}

class _SignedProofState extends State<_SignedProof> {
  late Future<String> _url = _fetch();

  Future<String> _fetch() =>
      context.read<StorageService>().proofUrl(widget.path);

  @override
  void didUpdateWidget(_SignedProof old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _url = _fetch();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _url,
    builder: (_, snap) => widget.builder(snap.data),
  );
}
