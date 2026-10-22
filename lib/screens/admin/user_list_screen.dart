import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/data.dart';
import '../../data/models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/common.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  static const _filters = <(String, UserRole?)>[
    ('Semua', null),
    ('Pemilik', UserRole.owner),
    ('Admin', UserRole.admin),
    ('Pet Sitter', UserRole.sitter),
  ];

  AdminStore get _store => context.read<AdminStore>();
  final _search = TextEditingController();
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppUser> _visible() {
    final role = _filters[_filter].$2;
    final q = _search.text.trim().toLowerCase();
    return _store.users.where((u) {
      if (role != null && u.role != role) return false;
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AdminStore>();
    final text = Theme.of(context).textTheme;

    final users = _visible();

    return Scaffold(
      appBar: const SubPageAppBar(title: 'Pengaturan Akun'),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau email',
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus',
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: FilterChipRow(
                labels: [for (final f in _filters) f.$1],
                selected: _filter,
                onSelected: (i) => setState(() => _filter = i),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${users.length} akun',
                      style: text.bodySmall!.copyWith(fontSize: 15),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.adminAddOnForm),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
          ),
          if (users.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.person_search_outlined,
                title: 'Akun tidak ditemukan',
                message: _search.text.isEmpty
                    ? 'Belum ada akun dengan peran ini.'
                    : 'Tidak ada akun yang cocok dengan '
                          '"${_search.text.trim()}".',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.xl,
              ),
              sliver: SliverList.separated(
                itemCount: users.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (_, i) => _UserCard(user: users[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.page,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(initial: user.initial, photo: user.photo, size: 64),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: text.titleLarge!.copyWith(fontSize: 19),
                    ),
                    Text(
                      user.email,
                      style: text.bodySmall!.copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.call_outlined,
                          size: 16,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            user.phone,
                            style: text.bodySmall!.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge.role(user.role.key),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Text(
            'Bergabung ${Fmt.date(user.joinedAt)}',
            style: text.labelSmall!.copyWith(fontSize: 13, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}
