import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/reservation_controller.dart';
import '../../../core/api_client.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/common.dart';

Future<bool> showApproveSheet(BuildContext context, Reservation r) async {
  final units = context.read<ReservationController>().freeUnits(
    r.roomType,
    r.checkIn,
    r.checkOut,
    ignore: r,
  );
  final unit = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ApproveSheet(reservation: r, units: units),
  );
  if (unit != null && context.mounted) {
    showSnack(context, 'Reservasi ${r.cat.name} dikonfirmasi di unit $unit');
  }
  return unit != null;
}

class _ApproveSheet extends StatefulWidget {
  const _ApproveSheet({required this.reservation, required this.units});

  final Reservation reservation;
  final List<String> units;

  @override
  State<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends State<_ApproveSheet> {
  late String? _unit = widget.units.isEmpty ? null : widget.units.first;
  bool _busy = false;

  /// kalo gagal, sheet tetap terbuka supaya admin bisa pilih unit lain
  Future<void> _approve() async {
    final unit = _unit!;
    setState(() => _busy = true);
    try {
      await context.read<ReservationController>().approve(
        widget.reservation,
        unit,
      );
      if (mounted) Navigator.pop(context, unit);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.md,
        ),
        child: Column(
          spacing: AppSpacing.lg,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Pilih unit kamar',
              subtitle:
                  'Unit ${r.roomType.name} tersedia '
                  '${Fmt.range(r.checkIn, r.checkOut)}',
            ),
            Column(
              spacing: AppSpacing.md,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.units.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Text(
                      'Semua unit penuh atau diblokir di tanggal ini. '
                      'Tolak reservasi atau buka blokir unit terlebih dahulu.',
                      style: text.bodyMedium!.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  )
                else
                  RadioGroup<String>(
                    groupValue: _unit,
                    onChanged: (v) => setState(() => _unit = v),
                    child: Column(
                      children: [
                        for (final u in widget.units)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _UnitOption(
                              unit: u,
                              selected: u == _unit,
                              onTap: () => setState(() => _unit = u),
                            ),
                          ),
                      ],
                    ),
                  ),
                Column(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _unit == null || _busy ? null : _approve,
                      child: const Text('Konfirmasi Reservasi'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                      child: const Text('Batal'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  const _UnitOption({
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final String unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF2FBFA) : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? AppColors.primarySoft : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            spacing: AppSpacing.xs,
            children: [
              Radio<String>(value: unit),
              Text('Unit $unit', style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> showRejectSheet(BuildContext context, Reservation r) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RejectSheet(reservation: r),
  );
  if (ok == true && context.mounted) {
    showSnack(context, 'Reservasi ${r.cat.name} ditolak');
  }
  return ok ?? false;
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.reservation});

  final Reservation reservation;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<ReservationController>().reject(
        widget.reservation,
        _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              spacing: AppSpacing.lg,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHeader(
                  title: 'Alasan penolakan',
                  subtitle:
                      'Alasan ini akan terlihat oleh pemilik di detail '
                      'reservasi.',
                ),
                LabeledField(
                  label: 'Alasan Penolakan',
                  required: true,
                  trailing: '${_reason.text.length}/250',
                  child: TextFormField(
                    controller: _reason,
                    autofocus: true,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 250,
                    buildCounter: (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                    decoration: const InputDecoration(
                      hintText: 'misal, Semua unit sedang dalam pemeliharaan',
                    ),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'Tulis alasan minimal 10 karakter'
                        : null,
                  ),
                ),
                Column(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      child: const Text('Tolak Reservasi'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                      ),
                      child: const Text('Batal'),
                    ),
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
