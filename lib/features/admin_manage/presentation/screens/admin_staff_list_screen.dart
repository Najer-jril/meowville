import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_back_link.dart';
import '../../../../core/widgets/app_icon_button.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../admin_rooms/presentation/widgets/room_form_controls.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_state_panels.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../domain/entities/staff_account.dart';
import '../../domain/repositories/admin_staff_repository.dart';
import '../../domain/usecases/staff_usecases.dart';
import '../admin_manage_routes.dart';
import '../widgets/staff_widgets.dart';

typedef StaffListController = DashboardController<List<StaffAccount>>;

class AdminStaffListScreen extends StatelessWidget {
  const AdminStaffListScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminManageRoutes.hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StaffListController>(
      create: (BuildContext context) => StaffListController(
        LoadStaffAccountsUseCase(context.read<AdminStaffRepository>()).call,
        fallbackMessage:
            'Daftar akun staf gagal dimuat. Coba ulangi sebentar lagi.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppBackLink(label: 'Kelola', onBack: () => _back(context)),
          Expanded(
            child: DashboardView<List<StaffAccount>>(
              loadingLabel: 'Memuat akun staf...',
              errorTitle: 'Akun staf belum bisa dimuat',
              skeletonHeights: const <double>[48, 48, 104, 104, 104],
              builder: (BuildContext context, List<StaffAccount> accounts) =>
                  <Widget>[_StaffList(accounts: accounts)],
            ),
          ),
        ],
      ),
    );
  }
}

enum _RoleFilter {
  all(null, 'Semua'),
  admin(UserRole.admin, 'Admin'),
  sitter(UserRole.petSitter, 'Penjaga');

  const _RoleFilter(this.role, this.label);

  final UserRole? role;
  final String label;
}

class _StaffList extends StatefulWidget {
  const _StaffList({required this.accounts});

  final List<StaffAccount> accounts;

  @override
  State<_StaffList> createState() => _StaffListState();
}

class _StaffListState extends State<_StaffList> {
  _RoleFilter _filter = _RoleFilter.all;

  Future<void> _create() async {
    final StaffListController controller = context.read<StaffListController>();
    await context.push(AdminManageRoutes.createStaff);
    // Akun baru dibuat di layar form, jadi daftar ditarik ulang saat kembali.
    await controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = context.watch<AuthNotifier>().user?.id;
    final List<StaffAccount> visible = filterStaffAccounts(
      widget.accounts,
      role: _filter.role,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPageHeader(
          title: 'Akun staf',
          subtitle: 'Penjaga dan admin yang bisa masuk ke Meowville.',
          action: AppIconButton(
            icon: Icons.person_add_alt_rounded,
            semanticLabel: 'Tambah akun staf',
            onPressed: _create,
          ),
        ),
        OptionChips<_RoleFilter>(
          options: <OptionChipItem<_RoleFilter>>[
            for (final _RoleFilter filter in _RoleFilter.values)
              OptionChipItem<_RoleFilter>(value: filter, label: filter.label),
          ],
          selected: _filter,
          onSelected: (_RoleFilter filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: AppSpacing.space20),
        if (visible.isEmpty)
          _EmptyState(filter: _filter, onCreate: _create)
        else
          for (int i = 0; i < visible.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space12),
            StaffAccountCard(
              account: visible[i],
              isCurrentUser: visible[i].id == currentUserId,
            ),
          ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.onCreate});

  final _RoleFilter filter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final (String title, String message) = switch (filter) {
      _RoleFilter.all => (
        'Belum ada akun staf',
        'Buat akun agar penjaga atau admin baru bisa masuk ke aplikasi.',
      ),
      _RoleFilter.admin => (
        'Belum ada akun admin',
        'Admin baru bisa mengonfirmasi reservasi dan mengelola kamar.',
      ),
      _RoleFilter.sitter => (
        'Belum ada akun penjaga',
        'Penjaga butuh akun untuk mencatat check-in, check-out, dan '
            'laporan harian kucing.',
      ),
    };
    return DashboardEmptyPanel(
      icon: Icons.badge_rounded,
      title: title,
      message: message,
      actionLabel: 'Tambah akun staf',
      onAction: onCreate,
    );
  }
}
