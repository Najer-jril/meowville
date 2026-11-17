import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../controllers/booking_controller.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/clock.dart';
import '../../../utils/format.dart';
import '../../../widgets/app_photo.dart';
import '../../../widgets/common.dart';
import '../../../widgets/photo_picker.dart';

abstract final class PaymentInfo {
  static const bank = 'BKA';
  static const bankName = 'Bank Kucing Asia';
  static const account = '1123 10 59';
  static const holder = 'Meowville Pethotel';
  static const adminWhatsApp = '0811-0000-1111';
}

StatusBadge ownerStatusBadge(Reservation r) {
  if (r.status == ReservationStatus.pending) {
    return StatusBadge(
      label: r.paymentProof == null
          ? 'Menunggu pembayaran'
          : 'Menunggu konfirmasi',
      style: AppBadges.booking('pending'),
    );
  }
  return StatusBadge.booking(r.status.key);
}

class OwnerBookingCard extends StatelessWidget {
  const OwnerBookingCard({super.key, required this.reservation, this.onTap});

  final Reservation reservation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final text = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: AppPhoto(r.cat.photo, size: 56, radius: 14),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text(
                    r.cat.name,
                    style: text.titleLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: ownerStatusBadge(r),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              [
                'Kamar ${r.roomType.name} \n',
                ?r.unit,
                Fmt.range(r.checkIn, r.checkOut),
                '\n ${r.nights} malam',
              ].join(' '),
              style: text.bodyMedium!.copyWith(color: AppColors.muted),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              Fmt.rupiah(r.total),
              style: text.labelLarge!.copyWith(
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProofDeadlineNotice extends StatelessWidget {
  const ProofDeadlineNotice(this.reservation, {super.key});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final left = context
        .read<BookingController>()
        .proofDeadline(reservation)
        .difference(Clock.now());
    if (left.isNegative) {
      return const NoticeBox.danger(
        icon: Icons.timer_off_outlined,
        message:
            'Batas unggah bukti bayar sudah lewat. Hubungi admin bila '
            'masih ingin melanjutkan.',
      );
    }
    return NoticeBox(
      icon: Icons.schedule,
      message: 'upload bukti bayar sebelum 24 jam setelah booking agar kamar tetap ditahan.',
    );
  }
}

class BankInfoCard extends StatelessWidget {
  const BankInfoCard({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              const Icon(
                Icons.account_balance_outlined,
                color: AppColors.primary,
              ),
              Expanded(
                child: Text(
                  'Cara pembayaran',
                  style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Transfer sebesar '),
                  TextSpan(
                    text: Fmt.rupiah(amount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' ke:'),
                ],
              ),
              style: text.bodyMedium!.copyWith(color: AppColors.muted),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PaymentInfo.bankName, style: text.bodySmall),
                      Text(
                        PaymentInfo.account,
                        style: text.titleLarge!.copyWith(
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      Text('a.n. ${PaymentInfo.holder}', style: text.bodySmall),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: PaymentInfo.account.replaceAll(' ', ''),
                      ),
                    );
                    showSnack(context, 'Nomor rekening disalin');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Salin'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showUploadProofSheet(
  BuildContext context, {
  required int amount,
  String? current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _UploadProofSheet(amount: amount, current: current),
  );
}

class _UploadProofSheet extends StatefulWidget {
  const _UploadProofSheet({required this.amount, this.current});

  final int amount;
  final String? current;

  @override
  State<_UploadProofSheet> createState() => _UploadProofSheetState();
}

class _UploadProofSheetState extends State<_UploadProofSheet> {
  late String? _picked = widget.current;

  Future<void> _pick() async {
    final path = await pickPhoto(context);
    if (path != null && mounted) setState(() => _picked = path);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final picked = _picked;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: SheetHeader(
                title: 'Unggah bukti bayar',
                subtitle: 'Satu gambar JPG atau PNG.',
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _pick,
                child: picked == null
                    ? Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          spacing: AppSpacing.sm,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconBubble(
                              icon: Icons.add_photo_alternate_outlined,
                              size: 56,
                            ),
                            Text(
                              'Pilih gambar',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      )
                    : AppPhoto(
                        picked,
                        size: 180,
                        placeholderIcon: Icons.receipt_long_outlined,
                      ),
              ),
            ),
            if (picked != null)
              Center(
                child: TextButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Ganti gambar'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Nominal transfer',
                        style: text.bodyMedium!.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Text(
                      Fmt.rupiah(widget.amount),
                      style: text.labelLarge!.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                bottom: AppSpacing.xs,
              ),
              child: FilledButton(
                onPressed: picked == null || picked == widget.current
                    ? null
                    : () => Navigator.pop(context, picked),
                child: const Text('Kirim Bukti'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showCancelReservationDialog(BuildContext context, Reservation r) {
  return showConfirmDialog(
    context,
    title: 'Batalkan reservasi?',
    message:
        'Reservasi ${r.cat.name} (${Fmt.range(r.checkIn, r.checkOut)}) '
        'akan dibatalkan dan kamar dilepas.',
    icon: Icons.event_busy,
    destructive: true,
    cancelLabel: 'Tidak',
    confirmLabel: 'Batalkan',
    extra: r.paymentProof == null
        ? null
        : const NoticeBox(
            icon: Icons.warning_amber_rounded,
            message:
                'Bukti bayar sudah diunggah. Hubungi admin untuk '
                'pengembalian dana setelah dibatalkan.',
          ),
  );
}

class CostBreakdownCard extends StatelessWidget {
  const CostBreakdownCard({
    super.key,
    required this.type,
    required this.nights,
    required this.addons,
    this.roomPrice,
  });

  final RoomType type;

  /// Harga per malam yang terkunci di reservasi tersimpan. Saat booking,
  /// default-nya [RoomType.price] yang berlaku sekarang.
  final int? roomPrice;
  final int nights;
  final List<Addon> addons;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final price = roomPrice ?? type.price;
    final total = price * nights + addons.fold<int>(0, (s, a) => s + a.price);

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
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              spacing: AppSpacing.sm,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                Text(
                  'Rincian biaya',
                  style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          line(
            'Kamar ${type.name} x $nights malam',
            price * nights,
            sub: '${Fmt.rupiah(price)}/malam',
          ),
          for (final a in addons) line(a.name, a.price),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(child: Text('Total', style: text.labelLarge)),
              Text(
                Fmt.rupiah(total),
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
