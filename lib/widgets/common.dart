import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color = AppColors.surface,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow ? AppShadows.soft : null,
      ),
      child: Material(
        color: color,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.style});

  StatusBadge.booking(String status, {super.key})
    : label = AppBadges.bookingLabel(status),
      style = AppBadges.booking(status);

  StatusBadge.role(String role, {super.key})
    : label = AppBadges.roleLabel(role),
      style = AppBadges.role(role);

  const StatusBadge.inactive({super.key})
    : label = 'Nonaktif',
      style = const BadgeStyle(AppColors.muted, AppColors.surfaceAlt);

  final String label;
  final BadgeStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: style.fg,
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: muted ? AppColors.muted : AppColors.text,
        ),
      ),
    );
  }
}

class SubPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SubPageAppBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      leadingWidth: 72,
      titleSpacing: 4,
      leading: Center(
        child: IconButton.filledTonal(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Kembali',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceAlt,
            foregroundColor: AppColors.text,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      actions: [
        ?trailing,
        const SizedBox(width: AppSpacing.page),
      ],
    );
  }
}

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.page),
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final active = i == selected;
          return Center(
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: active,
              onSelected: (_) => onSelected(i),
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? AppColors.primary : AppColors.text,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        },
      ),
    );
  }
}

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? AppColors.surface : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == selected ? AppShadows.soft : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: i == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == selected
                          ? AppColors.primaryDeep
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: text.bodyLarge!.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(
    this.label, {
    super.key,
    this.trailing,
    this.required = false,
  });

  final String label;
  final String? trailing;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                ],
              ),
              style: text.labelLarge,
            ),
          ),
          if (trailing != null) Text(trailing!, style: text.bodySmall),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall!.copyWith(fontSize: 14)),
          const SizedBox(width: AppSpacing.lg),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? text.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F766E),
            offset: Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.md,
          ),
          child: child,
        ),
      ),
    );
  }
}

ButtonStyle dangerOutlinedStyle() => OutlinedButton.styleFrom(
  foregroundColor: AppColors.danger,
  side: const BorderSide(color: AppColors.danger, width: 1.5),
);

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  bool destructive = false,
  IconData? icon,
  Widget? extra,
}) async {
  final tone = destructive ? AppColors.danger : AppColors.primary;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _AppDialog(
      icon: icon,
      iconColor: tone,
      iconBackground: destructive
          ? AppColors.dangerSoft
          : AppColors.primarySoft,
      title: title,
      message: message,
      extra: extra,
      actions: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              minimumSize: const Size(0, 48),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: tone,
              minimumSize: const Size(0, 48),
            ),
            child: Text(confirmLabel),
          ),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  IconData icon = Icons.warning_amber_rounded,
  String buttonLabel = 'Mengerti',
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _AppDialog(
      icon: icon,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningSoft,
      title: title,
      message: message,
      actions: [
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(buttonLabel),
          ),
        ),
      ],
    ),
  );
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.actions,
    this.extra,
  });

  final IconData? icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final Widget? extra;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconBubble(
                icon: icon!,
                color: iconColor,
                background: iconBackground,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleLarge!.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyLarge!.copyWith(color: AppColors.muted),
            ),
            if (extra != null) ...[
              const SizedBox(height: AppSpacing.lg),
              extra!,
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(children: actions),
          ],
        ),
      ),
    );
  }
}

class NoticeBox extends StatelessWidget {
  const NoticeBox({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline,
    this.color = AppColors.warning,
    this.background = AppColors.warningSoft,
    this.action,
  });

  const NoticeBox.danger({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.error_outline,
    this.action,
  }) : color = AppColors.danger,
       background = AppColors.dangerSoft;

  final String message;
  final String? title;
  final IconData icon;
  final Color color;
  final Color background;
  final Widget? action;

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
                ?action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: text.titleLarge!.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: text.bodyLarge!.copyWith(color: AppColors.muted),
          ),
        ],
      ],
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.size = 48,
    this.square = false,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(16) : null,
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
