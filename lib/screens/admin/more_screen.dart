import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final admin = context.watch<AdminStore>().currentAdmin;

    void push(String route, [Object? args]) =>
        Navigator.pushNamed(context, route, arguments: args);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xl,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            Text('Lainnya', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Row(
                children: [
                  UserAvatar(
                    initial: admin.initial,
                    photo: admin.photo,
                    size: 64,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin.name,
                          style: text.titleLarge!.copyWith(fontSize: 20),
                        ),
                        Text(
                          admin.email,
                          style: text.bodySmall!.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.role(admin.role.key),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Layanan Tambahan',
                    onTap: () => push(AppRoutes.adminAddOnList),
                  ),
                  const _Divider(),
                  _MenuTile(
                    icon: Icons.group_outlined,
                    title: 'Akun Pengguna',
                    onTap: () => push(AppRoutes.adminUserList),
                  ),
                  const _Divider(),
                  _MenuTile(
                    icon: Icons.bar_chart,
                    title: 'Laporan Pethotel',
                    onTap: () => push(AppRoutes.adminReport),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Tugas Ke Staff',
              style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            const _SitterTaskCard(),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              onTap: () => _confirmLogout(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                  vertical: AppSpacing.page,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.lg),
                    Text(
                      'Keluar',
                      style: text.labelLarge!.copyWith(
                        fontSize: 18,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk mengakses Meowville.',
      confirmLabel: 'Keluar',
      destructive: true,
      icon: Icons.logout,
    );
    if (ok && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }
}

class _SitterTaskCard extends StatelessWidget {
  const _SitterTaskCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final checkIns = store.awaitingCheckIn.length;
    final checkOuts = store.dueCheckOut.length;
    final unreported = store.staying
        .where((r) => store.reportToday(r) == null)
        .length;

    return AppCard(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.sitterHome, arguments: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(icon: Icons.pets, size: 48),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tugas Pet Sitter',
                      style: text.labelLarge!.copyWith(fontSize: 17),
                    ),
                    Text(
                      'Check-in/out dan laporan harian',
                      style: text.bodySmall!.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _TaskCount(value: checkIns, label: 'Check-in'),
              const SizedBox(width: AppSpacing.sm),
              _TaskCount(value: checkOuts, label: 'Check-out'),
              const SizedBox(width: AppSpacing.sm),
              _TaskCount(
                value: unreported,
                label: 'Belum lapor',
                warn: unreported > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskCount extends StatelessWidget {
  const _TaskCount({
    required this.value,
    required this.label,
    this.warn = false,
  });

  final int value;
  final String label;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = warn ? AppColors.warning : AppColors.primaryDeep;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: warn ? AppColors.warningSoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: text.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            Text(
              label,
              style: text.bodySmall!.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            IconBubble(icon: icon, size: 48),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                title,
                style: text.labelLarge!.copyWith(fontSize: 17),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(indent: AppSpacing.page, endIndent: AppSpacing.page);
}
