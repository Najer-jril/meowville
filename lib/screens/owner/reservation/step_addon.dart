import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/data.dart';
import '../../../data/models.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';

class StepAddon extends StatelessWidget {
  const StepAddon({super.key, required this.selected, required this.onToggle});

  final Set<Addon> selected;
  final ValueChanged<Addon> onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final addons = context.watch<AdminStore>().addons.where((a) => a.active);

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
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              'Opsional. Dikenakan sekali per reservasi.',
              style: text.bodyMedium!.copyWith(color: AppColors.muted),
            ),
          ),
          Column(
            spacing: AppSpacing.md,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final a in addons)
                _AddonOption(
                  addon: a,
                  selected: selected.contains(a),
                  onTap: () => onToggle(a),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddonOption extends StatelessWidget {
  const _AddonOption({
    required this.addon,
    required this.selected,
    required this.onTap,
  });

  final Addon addon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(value: selected, onChanged: (_) => onTap()),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addon.name, style: text.labelLarge),
                    Text(
                      addon.description,
                      style: text.bodySmall!.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(
                  Fmt.rupiah(addon.price),
                  style: text.labelLarge!.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
