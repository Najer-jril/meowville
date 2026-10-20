import 'package:flutter/material.dart';

import 'daily_report_form_screen.dart';
import 'report_history_screen.dart';
import 'sitter_account_screen.dart';

class SitterShell extends StatefulWidget {
  const SitterShell({super.key});

  @override
  State<SitterShell> createState() => _SitterShellState();
}

class _SitterShellState extends State<SitterShell> {
  int _index = 0;

  static const _pages = [
    DailyReportFormScreen(),
    ReportHistoryScreen(),
    SitterAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Hari Ini',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
