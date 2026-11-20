import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/settings_controller.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// open halaman web (privasi, ketentuan, hapus akun) di browser
Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) showSnack(context, 'Tidak bisa membuka $url');
}

/// CS lewat email. Alamatnya dari app_settings
Future<void> showSupportContact(BuildContext context, {String? subject}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => _SupportSheet(subject: subject),
  );
}

class _SupportSheet extends StatelessWidget {
  const _SupportSheet({this.subject});

  final String? subject;

  @override
  Widget build(BuildContext context) {
    final email = context.watch<SettingsController>().settings.supportEmail;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.page,
        ),
        child: Column(
          spacing: AppSpacing.lg,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(
              title: 'Hubungi tim Meowville',
              subtitle: 'Kirim pertanyaan atau permintaan lewat email.',
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Row(
                spacing: AppSpacing.sm,
                children: [
                  const Icon(Icons.mail_outline, color: AppColors.primary),
                  Expanded(
                    child: Text(
                      email,
                      style: text.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salin email',
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: email));
                      showSnack(context, 'Email disalin');
                    },
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: email,
                  query: subject == null
                      ? null
                      : 'subject=${Uri.encodeComponent(subject!)}',
                );
                final ok = await launchUrl(uri);
                if (!ok && context.mounted) {
                  showSnack(context, 'Tidak ada aplikasi email. Salin alamatnya saja.');
                }
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text('Kirim email'),
            ),
          ],
        ),
      ),
    );
  }
}

/// warning mode demo di layar pembayaran.
class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<SettingsController>().settings.demoMode) {
      return const SizedBox.shrink();
    }
    return const NoticeBox(
      title: 'Aplikasi demo',
      icon: Icons.info_outline,
      message:
          'Tidak ada transaksi nyata. Jangan transfer uang. '
          'Unggah gambar apa pun sebagai simulasi bukti bayar.',
    );
  }
}
