import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/staggered_entrance.dart';
import '../../../../core/widgets/village_skyline.dart';
import '../../domain/legal_document.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final int count = document.sections.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'Dokumen Meowville',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenEdge + 4,
              AppSpacing.space32,
              AppSpacing.screenEdge + 4,
              AppSpacing.space48,
            ),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: StaggeredEntrance(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'DOKUMEN HUKUM · $count BAGIAN',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.brandTerracottaDark,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Semantics(
                        header: true,
                        child: Text(
                          document.title,
                          style: AppTypography.display,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Text(
                          document.intro,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      _StatusNote(status: document.status),
                      const SizedBox(height: AppSpacing.space16),
                      for (int i = 0; i < count; i++)
                        _SectionBlock(
                          index: i + 1,
                          section: document.sections[i],
                        ),
                      const SizedBox(height: AppSpacing.space40),
                      const VillageSkyline(
                        height: 48,
                        houseColor: AppColors.surfaceContainerHigh,
                        windowColor: AppColors.surface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.status});

  final LegalDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColors.pendingSurface,
          borderRadius: AppRadius.cardAll,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const ColoredBox(
                color: AppColors.pendingAccent,
                child: SizedBox(width: 4),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 22,
                          color: AppColors.pendingText,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              status.label,
                              style: AppTypography.labelLg.copyWith(
                                color: AppColors.pendingText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space4),
                            Text(
                              status.detail,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.pendingText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.index, required this.section});

  final int index;
  final LegalSection section;

  static const double _numberColumn = 40;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = AppTypography.bodyMd.copyWith(
      height: 1.65,
      color: AppColors.onSurface,
    );

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.space16),
      padding: const EdgeInsets.only(top: AppSpacing.space20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: _numberColumn,
            child: ExcludeSemantics(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.brandTerracottaDark,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(section.heading, style: AppTypography.headlineSm),
                ),
                const SizedBox(height: AppSpacing.space12),
                for (final String paragraph in section.paragraphs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space12),
                    child: Text(paragraph, style: body),
                  ),
                for (final String point in section.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 10,
                          height: 2,
                          margin: const EdgeInsets.only(
                            top: 11,
                            right: AppSpacing.space12,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.brandTerracotta,
                            borderRadius: AppRadius.pillAll,
                          ),
                        ),
                        Expanded(child: Text(point, style: body)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
