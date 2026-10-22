import 'package:flutter/material.dart';

import '../../widgets/legal_document.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => const LegalDocument(
    appBarTitle: 'Kebijakan Meowville',
    overline: 'Kebijakan',
    title: 'Kebijakan Meowville',
    subtitle: 'Cara kami menjaga setiap kucing seperti keluarga sendiri.',
    updatedAt: 'Diperbarui 8 April 2026',
    icon: Icons.favorite_border,
    sections: [
      LegalSection(
        'Perlakuan penuh kasih',
        'Setiap kucing ditangani dengan lembut. Kami tidak menggunakan kekerasan atau paksaan dalam bentuk apa pun.',
      ),
      LegalSection(
        'Kamar yang nyaman',
        'Setiap kucing menempati kamar sendiri yang bersih dan dirapikan setiap hari sesuai tipe yang dipesan.',
      ),
      LegalSection(
        'Makan dan minum',
        'Makan dan minum diberikan sesuai paket tipe kamar. Nafsu makan dan minum dicatat dalam laporan harian.',
      ),
      LegalSection(
        'Pemantauan harian',
        'Pet sitter mencatat makan, minum, mood, dan catatan kondisi. Laporan dapat dilihat pemilik di aplikasi selama kucing menginap.',
      ),
      LegalSection(
        'Kondisi darurat',
        'Jika kucing tampak sakit atau lesu berkepanjangan, tim kami menghubungi pemilik melalui WhatsApp secepatnya.',
      ),
      LegalSection(
        'Privasi',
        'Foto dan data kucing hanya dapat dilihat oleh pemilik dan tim Meowville.',
      ),
      LegalSection(
        'Komunikasi',
        'Pemilik dapat menghubungi admin melalui WhatsApp untuk pertanyaan, perubahan, atau kekhawatiran selama masa penitipan.',
      ),
    ],
  );
}
