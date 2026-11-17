import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../routes/app_routes.dart';

import '../../../controllers/booking_controller.dart';
import '../../../controllers/pet_controller.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../widgets/app_photo.dart';
import '../../../widgets/common.dart';
import '../../../utils/clock.dart';

class StepPetDate extends StatelessWidget {
  const StepPetDate({
    super.key,
    required this.range,
    required this.cat,
    required this.onRangeChanged,
    required this.onCatChanged,
  });

  final DateTimeRange? range;
  final Cat? cat;
  final ValueChanged<DateTimeRange> onRangeChanged;
  final ValueChanged<Cat> onCatChanged;

  Future<void> _pickRange(BuildContext context) async {
    final today = Clock.today();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      initialDateRange: range,
      helpText: 'Pilih tanggal menginap',
      saveText: 'Simpan',
    );
    if (picked == null) return;
    if (picked.duration.inDays < 1) {
      onRangeChanged(
        DateTimeRange(
          start: picked.start,
          end: picked.start.add(const Duration(days: 1)),
        ),
      );
    } else {
      onRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingController>();
    final text = Theme.of(context).textTheme;
    final heading = text.titleLarge!.copyWith(fontWeight: FontWeight.w700);
    final r = range;

    final cats = context.watch<PetController>().cats;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text('Tanggal menginap', style: heading),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Check-in',
                    icon: Icons.login,
                    value: r?.start,
                    onTap: () => _pickRange(context),
                  ),
                ),
                Expanded(
                  child: _DateField(
                    label: 'Check-out',
                    icon: Icons.logout,
                    value: r?.end,
                    onTap: () => _pickRange(context),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: r == null
                ? Text('Minimal 1 malam.', style: text.bodySmall)
                : StatusBadge(
                    label: '${r.duration.inDays} malam',
                    style: const BadgeStyle(
                      AppColors.primaryDeep,
                      AppColors.primarySoft,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xl,
              bottom: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(child: Text('Pilih kucing', style: heading)),
                Text('Wajib dipilih', style: text.bodySmall),
              ],
            ),
          ),
          if (cats.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.pets,
                title: 'Belum ada kucing',
                message: 'Tambahkan kucing terlebih dahulu.',
                action: OutlinedButton.icon(
                  onPressed: () => _addCat(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kucing'),
                ),
              ),
            )
          else ...[
            if (r == null)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: NoticeBox(
                  message:
                      'Pilih tanggal dulu untuk melihat kucing yang bisa '
                      'menginap.',
                  color: AppColors.info,
                  background: AppColors.infoSoft,
                ),
              ),
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CatOption(
                  cat: c,
                  selected: c == cat,
                  clash: r == null ? null : booking.clashFor(c, r.start, r.end),
                  enabled: r != null,
                  onTap: () => onCatChanged(c),
                ),
              ),
            TextButton.icon(
              onPressed: () => _addCat(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah kucing baru'),
            ),
          ],
        ],
      ),
    );
  }

  void _addCat(BuildContext context) =>
      Navigator.pushNamed(context, AppRoutes.ownerPetForm);
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      spacing: AppSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodySmall!.copyWith(fontSize: 14)),
        Material(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.input),
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(
                height: AppSizes.fieldLg,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    Expanded(
                      child: Text(
                        value == null ? 'Pilih tanggal' : Fmt.date(value!),
                        style: value == null
                            ? text.bodyLarge!.copyWith(color: AppColors.muted)
                            : text.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatOption extends StatelessWidget {
  const _CatOption({
    required this.cat,
    required this.selected,
    required this.clash,
    required this.enabled,
    required this.onTap,
  });

  final Cat cat;
  final bool selected;
  final Reservation? clash;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final blocked = clash != null;
    final active = enabled && !blocked;

    final card = Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: active ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: AppPhoto(cat.photo, size: 56, radius: 14),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: text.titleLarge),
                    Text(
                      blocked
                          ? 'Sudah ada reservasi '
                                '${Fmt.range(clash!.checkIn, clash!.checkOut)}'
                          : '${cat.breedLabel} - ${cat.weightLabel}',
                      style: text.bodySmall!.copyWith(
                        fontSize: 14,
                        color: blocked ? AppColors.warning : null,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                blocked
                    ? Icons.block
                    : selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
    return active || selected ? card : Opacity(opacity: 0.55, child: card);
  }
}
