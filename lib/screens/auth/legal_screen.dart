import 'package:flutter/material.dart';

import '../../widgets/legal_document.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) => const LegalDocument(
    appBarTitle: 'Ketentuan Layanan Meowville',
    overline: 'Ketentuan',
    title: 'Ketentuan Layanan Meowville',
    subtitle: 'Apa-apa saja yang harus anda ketahui sebelum daftar akun di aplikasi ini',
    updatedAt: 'Diperbarui 8 April 2026',
    icon: Icons.favorite_border,
    sections: [
      LegalSection(
        'Ruang Lingkup Layanan',
        'Meowville menyediakan penitipan khusus kucing. Layanan mencakup kamar sesuai tipe yang dipesan, paket bawaan tipe tersebut, layanan tambahan yang dipilih, dan laporan kondisi harian.',
      ),
      LegalSection(
        'Data dan kondisi kucing',
        'Pemilik wajib mengisi data kucing dengan benar dan menitipkan kucing dalam kondisi sehat. Kondisi khusus sebaiknya diinformasikan kepada admin melalui WhatsApp saat check-in.',
      ),
      LegalSection(
        'Reservasi dan pembayaran',
        'Reservasi berstatus Menunggu sampai dikonfirmasi admin. Harga dihitung per malam dan dikunci saat reservasi dikirim. Unggah bukti bayar agar reservasi dapat diproses.',
      ),
      LegalSection(
        'Penahanan kamar',
        'Reservasi tanpa bukti bayar menahan kamar maksimal 24 jam. Setelah itu kamar dapat dipesan pemilik lain.',
      ),
      LegalSection(
        'Check-in dan check-out',
        'Lama menginap dihitung per malam. Hari check-out tidak dihitung sebagai malam menginap. Kode unit kamar ditetapkan admin saat reservasi dikonfirmasi.',
      ),
      LegalSection(
        'Layanan tambahan',
        'Layanan tambahan dikenakan satu kali per reservasi sesuai harga saat dipesan.',
      ),
      LegalSection(
        'Pembatalan dan pengembalian dana',
        'Reservasi berstatus Menunggu dapat dibatalkan langsung di aplikasi. Reservasi yang sudah dikonfirmasi dibatalkan melalui admin lewat WhatsApp. Pengembalian dana diproses admin secara manual.',
      ),
    ],
  );
}
