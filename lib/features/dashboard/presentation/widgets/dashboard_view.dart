import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../providers/dashboard_controller.dart';
import 'dashboard_skeleton.dart';
import 'dashboard_state_panels.dart';

class DashboardView<T> extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.loadingLabel,
    required this.builder,
    this.skeletonHeights = const <double>[148, 96, 96],
    this.errorTitle = 'Dashboard belum bisa dimuat',
  });

  final String loadingLabel;
  final String errorTitle;
  final List<double> skeletonHeights;
  final List<Widget> Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final DashboardController<T> controller = context
        .watch<DashboardController<T>>();

    switch (controller.status) {
      case DashboardStatus.loading:
        if (controller.data == null) {
          return DashboardSkeleton(
            label: loadingLabel,
            blockHeights: skeletonHeights,
          );
        }
        return _content(context, controller, controller.data as T);
      case DashboardStatus.failure:
        return SingleChildScrollView(
          child: DashboardErrorPanel(
            title: errorTitle,
            message:
                controller.errorMessage ?? 'Coba ulangi beberapa saat lagi.',
            onRetry: controller.load,
          ),
        );
      case DashboardStatus.ready:
        return _content(context, controller, controller.data as T);
    }
  }

  Widget _content(
    BuildContext context,
    DashboardController<T> controller,
    T data,
  ) {
    return RefreshIndicator(
      color: AppColors.brandTerracottaDark,
      onRefresh: controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenEdge,
          AppSpacing.space24,
          AppSpacing.screenEdge,
          AppSpacing.space32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: StaggeredEntrance(children: builder(context, data)),
          ),
        ),
      ),
    );
  }
}
