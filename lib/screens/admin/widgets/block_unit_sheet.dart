import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/data.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/common.dart';

Future<void> showBlockUnitSheet(BuildContext context, RoomType type) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BlockUnitSheet(type: type),
  );
  if (ok == true && context.mounted) showSnack(context, 'Unit diblokir');
}

class _BlockUnitSheet extends StatefulWidget {
  const _BlockUnitSheet({required this.type});

  final RoomType type;

  @override
  State<_BlockUnitSheet> createState() => _BlockUnitSheetState();
}

class _BlockUnitSheetState extends State<_BlockUnitSheet> {
  AdminStore get _store => context.read<AdminStore>();
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late String _unit = widget.type.units.first;
  late DateTime _start = _store.today;
  late DateTime _end = _store.today.add(const Duration(days: 1));
  String? _error;

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

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: start ? _store.today : _start,
      lastDate: _store.today.add(const Duration(days: 365)),
      helpText: start ? 'Tanggal mulai' : 'Tanggal selesai',
    );
    if (picked == null) return;
    setState(() {
      _error = null;
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final error = _store.addBlock(
      type: widget.type,
      unit: _unit,
      start: _start,
      end: _end,
      reason: _reason.text.trim(),
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    Widget dateField(String label, DateTime value, bool start) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: InkWell(
              onTap: () => _pick(start),
              borderRadius: BorderRadius.circular(AppRadius.input),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(Fmt.date(value), style: text.bodyLarge),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
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
                const SheetHeader(title: 'Blokir unit'),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: text.bodyMedium!.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text('Unit', style: text.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _unit,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  items: [
                    for (final u in widget.type.units)
                      DropdownMenuItem(
                        value: u,
                        child: Text('Unit $u (${widget.type.name})'),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _unit = v!;
                    _error = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    dateField('Tanggal mulai', _start, true),
                    const SizedBox(width: AppSpacing.md),
                    dateField('Tanggal selesai', _end, false),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tanggal selesai termasuk hari terakhir unit tidak bisa '
                  'dipakai',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: Text('Alasan', style: text.bodyMedium)),
                    Text('${_reason.text.length}/100', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _reason,
                  maxLength: 100,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  decoration: const InputDecoration(hintText: 'misal, AC rusak'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Alasan wajib diisi'
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Simpan Blokir'),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
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
