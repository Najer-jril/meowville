import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LegalSection {
  final String title;
  final String body;
  const LegalSection(this.title, this.body);
}

class LegalDocument extends StatelessWidget {
  const LegalDocument({
    super.key,
    required this.appBarTitle,
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.icon,
    required this.sections,
  });

  final String appBarTitle;
  final String overline;
  final String title;
  final String subtitle;
  final String updatedAt;
  final IconData icon;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.page,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          children: [
            _Header(title: appBarTitle),
            const SizedBox(height: 20),
            _IntroCard(
              overline: overline,
              title: title,
              subtitle: subtitle,
              updatedAt: updatedAt,
              icon: icon,
            ),
            const SizedBox(height: AppSpacing.lg),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    _Pasal(number: i + 1, section: sections[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(onPressed: () => Navigator.pop(context)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      boxShadow: AppShadows.soft,
    ),
    child: child,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.text,
              semanticLabel: 'Kembali',
            ),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
    ],
  );
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.icon,
  });

  final String overline, title, subtitle, updatedAt;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.96,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.375,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                updatedAt,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ],
    ),
  );
}

class _Pasal extends StatelessWidget {
  const _Pasal({required this.number, required this.section});
  final int number;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number.toString().padLeft(2, '0'),
              style: head.copyWith(color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                section.title,
                style: head.copyWith(color: AppColors.text),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Divider(height: 1, color: AppColors.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          section.body,
          style: const TextStyle(
            fontSize: 15,
            height: 24 / 15,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.page,
      vertical: AppSpacing.lg,
    ),
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
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: onPressed,
          child: const Text('Saya mengerti'),
        ),
      ),
    ),
  );
}
