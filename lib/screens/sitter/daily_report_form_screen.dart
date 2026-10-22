import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class DailyReportFormScreen extends StatefulWidget {
  const DailyReportFormScreen({
    super.key,
    required this.reservation,
    required this.actor,
  });

  final Reservation reservation;
  final AppUser actor;

  @override
  State<DailyReportFormScreen> createState() => _DailyReportFormScreenState();
}

class _DailyReportFormScreenState extends State<DailyReportFormScreen> {
  AdminStore get _store => context.read<AdminStore>();
  final _note = TextEditingController();
  String? _food;
  String? _drink;
  String? _mood;
  String? _photo;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _complete => _food != null && _drink != null && _mood != null;

  void _submit() {
    setState(() => _submitted = true);
    if (!_complete) return;
    _store.addReport(
      reservation: widget.reservation,
      reporter: widget.actor,
      food: _food!,
      drink: _drink!,
      mood: _mood!,
      note: _note.text.trim(),
      photo: _photo,
    );
    Navigator.pop(context);
    showSnack(context, 'Laporan ${widget.reservation.cat.name} terkirim');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reservation;
    final text = Theme.of(context).textTheme;
    final previous = _store.reportToday(r);
    final showErrors = _submitted && !_complete;

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Laporan Harian'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          if (showErrors) ...[
            _Banner(
              icon: Icons.error,
              color: AppColors.danger,
              background: AppColors.dangerSoft,
              title: 'Data belum lengkap',
              message:
                  'Harap pilih status makan, minum, dan mood '
                  '${r.cat.name} terlebih dahulu.',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (previous != null) ...[
                  _Banner(
                    icon: Icons.info_outline,
                    color: AppColors.warning,
                    background: AppColors.warningSoft,
                    message:
                        '${r.cat.name} sudah dilaporkan '
                        '${previous.reporter.firstName}, '
                        '${Fmt.time(previous.time)}. Tetap kirim laporan baru?',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Row(
                  children: [
                    AppPhoto(r.cat.photo, size: 56, radius: 14),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.cat.name, style: text.titleLarge),
                          Text(
                            'Kamar ${r.roomType.name} ${r.unit ?? ''}',
                            style: text.bodySmall!.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: Fmt.time(_store.now),
                      style: const BadgeStyle(
                        AppColors.muted,
                        AppColors.surfaceAlt,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl * 1.5),
                _ChoiceGroup(
                  label: 'Makan',
                  options: DailyReport.foodOptions,
                  value: _food,
                  error: _submitted && _food == null,
                  onChanged: (v) => setState(() => _food = v),
                ),
                _ChoiceGroup(
                  label: 'Minum',
                  options: DailyReport.drinkOptions,
                  value: _drink,
                  error: _submitted && _drink == null,
                  onChanged: (v) => setState(() => _drink = v),
                ),
                _ChoiceGroup(
                  label: 'Mood',
                  options: DailyReport.moodOptions,
                  value: _mood,
                  error: _submitted && _mood == null,
                  onChanged: (v) => setState(() => _mood = v),
                ),
                FieldLabel('Catatan', trailing: '${_note.text.length}/200'),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 200,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'deskripsi singkat kondisi kucingnya',
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const FieldLabel('Foto'),
                _PhotoPicker(
                  photo: _photo,
                  onPick: () => setState(() => _photo = r.cat.photo),
                  onRemove: () => setState(() => _photo = null),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Kirim Laporan'),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.message,
    this.title,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: text.labelLarge!.copyWith(
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                Text(message, style: text.bodyMedium!.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.options,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String? value;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel(
            label,
            required: true,
            trailing: error ? 'Wajib diisi' : null,
          ),
          Container(
            padding: error ? const EdgeInsets.all(6) : EdgeInsets.zero,
            decoration: error
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.danger, width: 1.5),
                  )
                : null,
            child: LayoutBuilder(
              builder: (context, c) {
                const gap = AppSpacing.sm;
                final perRow = options.length > 3 ? 2 : 3;
                final width = (c.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final o in options)
                      SizedBox(
                        width: width,
                        child: _Pill(
                          label: o,
                          selected: o == value,
                          onTap: () => onChanged(o),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (error)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.error, size: 18, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    'Pilih salah satu',
                    style: text.bodySmall!.copyWith(color: AppColors.danger),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.primaryDeep : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  final String? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            AppPhoto(photo, size: 112),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                tooltip: 'Hapus foto',
                onPressed: onRemove,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.close, size: 18),
              ),
            ),
          ],
        ),
      );
    }
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconBubble(
                icon: Icons.photo_camera_outlined,
                background: AppColors.surface,
                size: 48,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'tambahin foto kucingnya',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
