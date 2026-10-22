import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../theme/app_theme.dart';
import 'report_history_screen.dart';
import 'account_screen.dart';
import 'today_screen.dart';

class SitterShell extends StatefulWidget {
  const SitterShell({super.key, this.asAdmin = false});

  final bool asAdmin;

  @override
  State<SitterShell> createState() => _SitterShellState();
}

class _SitterShellState extends State<SitterShell> {
  AdminStore get _store => context.read<AdminStore>();
  int _index = 0;

  late final _actor = widget.asAdmin
      ? _store.currentAdmin
      : _store.currentSitter;

  late final _pages = [
    SitterTodayScreen(actor: _actor),
    const ReportHistoryScreen(),
    if (!widget.asAdmin) SitterAccountScreen(user: _actor),
  ];

  @override
  Widget build(BuildContext context) {
    Widget body = IndexedStack(index: _index, children: _pages);
    if (widget.asAdmin) {
      body = Column(
        children: [
          const _AdminModeBar(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: body,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Hari Ini',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Riwayat',
          ),
          if (!widget.asAdmin)
            const NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
        ],
      ),
    );
  }
}

class _AdminModeBar extends StatelessWidget {
  const _AdminModeBar();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      color: AppColors.secondarySoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Mode Pet Sitter',
                  style: text.bodySmall!.copyWith(
                    fontSize: 12,
                    color: AppColors.adminRole,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.adminRole,
                  side: const BorderSide(color: AppColors.adminRole),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: text.labelLarge!.copyWith(fontSize: 14),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
