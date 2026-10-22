import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/data.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/common.dart';

Future<bool> showApproveSheet(BuildContext context, Reservation r) async {
  final store = context.read<AdminStore>();
  final units = store.freeUnits(r.roomType, r.checkIn, r.checkOut, ignore: r);
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ApproveSheet(reservation: r, units: units),
  );
  if (ok == true && context.mounted) {
    showSnack(
      context,
      'Reservasi ${r.cat.name} dikonfirmasi di unit ${r.unit}',
    );
  }
  return ok ?? false;
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: 'Pilih unit kamar',
              subtitle:
                  'Unit ${r.roomType.name} tersedia '
                  '${Fmt.range(r.checkIn, r.checkOut)}',
            ),
            const SizedBox(height: AppSpacing.lg),
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
                  style: text.bodyMedium!.copyWith(color: AppColors.warning),
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
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _UnitOption(
                          unit: u,
                          selected: u == _unit,
                          onTap: () => setState(() => _unit = u),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _unit == null
                  ? null
                  : () {
                      context.read<AdminStore>().approve(r, _unit!);
                      Navigator.pop(context, true);
                    },
              child: const Text('Konfirmasi Reservasi'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: const Text('Batal'),
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
            children: [
              Radio<String>(value: unit),
              const SizedBox(width: AppSpacing.xs),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AdminStore>().reject(widget.reservation, _reason.text.trim());
    Navigator.pop(context, true);
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetHeader(
                  title: 'Alasan penolakan',
                  subtitle:
                      'Alasan ini akan terlihat oleh pemilik di detail '
                      'reservasi.',
                ),
                const SizedBox(height: AppSpacing.lg),
                FieldLabel(
                  'Alasan Penolakan',
                  required: true,
                  trailing: '${_reason.text.length}/250',
                ),
                TextFormField(
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
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  child: const Text('Tolak Reservasi'),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
