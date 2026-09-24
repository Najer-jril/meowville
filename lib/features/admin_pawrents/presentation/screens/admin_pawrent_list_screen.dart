import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_state_panels.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../../dashboard/presentation/widgets/filter_segmented_tabs.dart';
import '../../domain/entities/pawrent.dart';
import '../../domain/repositories/admin_pawrent_repository.dart';
import '../../domain/usecases/load_pawrents_usecase.dart';
import '../admin_pawrent_routes.dart';
import '../widgets/pawrent_widgets.dart';

typedef PawrentListController = DashboardController<List<PawrentSummary>>;

class AdminPawrentListScreen extends StatelessWidget {
  const AdminPawrentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PawrentListController>(
      create: (BuildContext context) => PawrentListController(
        LoadPawrentsUseCase(context.read<AdminPawrentRepository>()).call,
        fallbackMessage:
            'Daftar pawrent gagal dimuat. Coba ulangi sebentar lagi.',
      ),
      child: DashboardView<List<PawrentSummary>>(
        loadingLabel: 'Memuat daftar pawrent...',
        errorTitle: 'Daftar pawrent belum bisa dimuat',
        skeletonHeights: const <double>[48, 48, 52, 104, 104, 104],
        builder: (BuildContext context, List<PawrentSummary> pawrents) =>
            <Widget>[_PawrentList(pawrents: pawrents)],
      ),
    );
  }
}

class _PawrentList extends StatefulWidget {
  const _PawrentList({required this.pawrents});

  final List<PawrentSummary> pawrents;

  @override
  State<_PawrentList> createState() => _PawrentListState();
}

class _PawrentListState extends State<_PawrentList> {
  final TextEditingController _search = TextEditingController();
  PawrentFilter _filter = PawrentFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(PawrentSummary pawrent) async {
    final PawrentListController controller = context
        .read<PawrentListController>();
    await context.push(AdminPawrentRoutes.detail(pawrent.id));
    // Status reservasi bisa berubah dari detail, jadi daftar ditarik ulang.
    await controller.refresh();
  }

  void _clearSearch() {
    _search.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int stayingCount = filterPawrents(
      widget.pawrents,
      filter: PawrentFilter.staying,
    ).length;
    final List<PawrentSummary> visible = filterPawrents(
      widget.pawrents,
      filter: _filter,
      query: _search.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPageHeader(
          title: 'Pawrent',
          subtitle: widget.pawrents.isEmpty
              ? 'Belum ada pawrent terdaftar.'
              : '${widget.pawrents.length} pawrent terdaftar.',
        ),
        AppTextField(
          controller: _search,
          hintText: 'Cari nama atau email',
          semanticLabel: 'Cari nama atau email pawrent',
          icon: Icons.search_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.space12),
        FilterSegmentedTabs(
          options: <FilterTabOption>[
            FilterTabOption(label: 'Semua', count: widget.pawrents.length),
            FilterTabOption(label: 'Sedang Menginap', count: stayingCount),
          ],
          selectedIndex: _filter.index,
          onSelected: (int index) =>
              setState(() => _filter = PawrentFilter.values[index]),
        ),
        const SizedBox(height: AppSpacing.space20),
        if (visible.isEmpty)
          _EmptyState(
            filter: _filter,
            query: _search.text.trim(),
            onClearSearch: _clearSearch,
          )
        else
          for (int i = 0; i < visible.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space12),
            PawrentCard(pawrent: visible[i], onTap: () => _open(visible[i])),
          ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
    required this.query,
    required this.onClearSearch,
  });

  final PawrentFilter filter;
  final String query;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    if (query.isNotEmpty) {
      return DashboardEmptyPanel(
        icon: Icons.search_off_rounded,
        title: 'Tidak ada pawrent yang cocok dengan "$query"',
        message: filter == PawrentFilter.staying
            ? 'Pencarian hanya di pawrent yang kucingnya sedang menginap. '
                  'Pilih Semua untuk mencari di seluruh pawrent.'
            : 'Periksa ejaan nama atau alamat email.',
        actionLabel: 'Hapus pencarian',
        onAction: onClearSearch,
      );
    }
    return switch (filter) {
      PawrentFilter.all => const DashboardEmptyPanel(
        icon: Icons.people_outline_rounded,
        title: 'Belum ada pawrent terdaftar',
        message:
            'Pemilik kucing tampil di sini setelah mendaftar lewat aplikasi.',
      ),
      PawrentFilter.staying => const DashboardEmptyPanel(
        icon: Icons.bed_rounded,
        title: 'Tidak ada kucing yang sedang menginap',
        message:
            'Pawrent tampil di sini selama reservasinya berstatus '
            'Sedang Menginap.',
      ),
    };
  }
}
