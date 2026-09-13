import '../domain/legal_document.dart';

abstract final class LegalDocuments {
  static const LegalDocumentStatus _draftStatus = LegalDocumentStatus(
    label: 'data dummy, belum final',
    detail:
        'masih dummy ya dul, belum final, data juga diambil dari internet',
  );

  static const LegalDocument ketentuanLayananPenitipan = LegalDocument(
    title: 'Ketentuan Layanan Penitipan',
    intro:
        'Ketentuan ini mengatur penitipan kucing Anda di Meowville: apa yang '
        'kami kerjakan, apa yang kami minta dari Anda, dan apa yang terjadi '
        'kalau ada yang meleset.',
    status: _draftStatus,
    sections: <LegalSection>[
      LegalSection(
        heading: 'Siapa kami',
        paragraphs: <String>[
          'Meowville adalah layanan penitipan kucing harian dan menginap.',
        ],
      ),
      LegalSection(
        heading: 'Syarat kucing yang dititipkan',
        paragraphs: <String>[
          'Kami menolak penitipan kalau salah satu syarat di bawah tidak '
              'terpenuhi, walau reservasi sudah dibayar.',
        ],
        points: <String>[
          'Usia minimal 3 bulan dan sudah lepas sapih.',
          'Sudah divaksin lengkap (Tricat/FVRCP, minimal 2 dosis) dan '
              'vaksinasi terakhir tidak lebih dari 1 tahun, dan Anda '
              'membawa buktinya (buku vaksin atau catatan dokter hewan) saat '
              'menitipkan.',
          'Bebas kutu, jamur, dan penyakit menular pada hari penitipan.',
          'Kucing yang sedang hamil, menyusui, atau dalam pengobatan wajib '
              'Anda beri tahu sebelum reservasi.',
        ],
      ),
      LegalSection(
        heading: 'Reservasi, pembayaran, dan pembatalan',
        points: <String>[
          'Reservasi terhitung sah setelah Anda membayar uang muka minimal '
              '50% dari total biaya menginap.',
          'Tarif menginap per malam: Rp75.000 (kamar reguler) / Rp110.000 '
              '(kamar VIP dengan CCTV).',
          'Pembatalan oleh Anda: dibatalkan lebih dari 2x24 jam sebelum '
              'jadwal check-in, uang muka dikembalikan penuh; kurang dari '
              'itu, uang muka hangus.',
          'Kalau kami yang membatalkan karena kamar rusak atau ada wabah di '
              'rumah penitipan, Anda mendapat pengembalian penuh.',
        ],
      ),
      LegalSection(
        heading: 'Mengantar dan menjemput',
        points: <String>[
          'Jam antar jemput: setiap hari pukul 08.00-20.00 WIB.',
          'Terlambat menjemput dikenakan biaya Rp50.000 per hari '
              'keterlambatan, dihitung sejak jam operasional berakhir.',
          'Kalau kucing tidak dijemput sampai 14 hari sejak tanggal '
              'seharusnya pulang dan Anda tidak bisa dihubungi lewat nomor '
              'yang terdaftar, kami akan menempuh langkah menitipkan kucing '
              'ke yayasan atau komunitas pecinta kucing rekanan kami untuk '
              'perawatan lanjutan. Kami tidak akan menjual atau mengalihkan '
              'kucing Anda.',
        ],
      ),
      LegalSection(
        heading: 'Kalau kucing Anda sakit saat dititipkan',
        paragraphs: <String>[
          'Kami menghubungi Anda lebih dulu lewat nomor WhatsApp yang '
              'terdaftar. Kalau dalam keadaan darurat Anda tidak bisa dihubungi, '
              'kami membawa kucing ke dokter hewan tanpa menunggu jawaban Anda.',
        ],
        points: <String>[
          'Biaya pemeriksaan dan pengobatan ditanggung Anda sebagai pemilik.',
          'Kami menyimpan dan menyerahkan seluruh nota dari dokter hewan.',
        ],
      ),
      LegalSection(
        heading: 'Barang yang Anda titipkan bersama kucing',
        paragraphs: <String>[
          'Kandang, mainan, alas, dan pakaian boleh dititipkan, tapi kami '
              'tidak mengganti barang yang hilang atau rusak. Beri nama pada '
              'setiap barang.',
        ],
      ),
      LegalSection(
        heading: 'Batas tanggung jawab kami',
        paragraphs: <String>[
          'Kami bertanggung jawab atas kelalaian yang kami lakukan, misalnya '
              'kucing tidak diberi makan sesuai jadwal atau kandang tidak '
              'dikunci.',
          'Kami tidak bertanggung jawab atas penyakit bawaan yang belum '
              'muncul saat penitipan dimulai, dan atas kondisi yang tidak Anda '
              'beri tahu saat reservasi.',
          'Nilai ganti rugi maksimal: setara total biaya penitipan yang '
              'sudah dibayarkan untuk masa inap tersebut.',
        ],
      ),
      LegalSection(
        heading: 'Perubahan ketentuan',
        paragraphs: <String>[
          'Kalau kami mengubah ketentuan ini, versi barunya kami tampilkan di '
              'halaman ini dan kami beri tahu lewat WhatsApp sebelum berlaku. '
              'Reservasi yang sudah berjalan tetap memakai ketentuan yang Anda '
              'setujui saat memesan.',
        ],
      ),
      LegalSection(
        heading: 'Bertanya atau mengadu',
        paragraphs: <String>[
          'Hubungi WhatsApp 0812-3456-7890 atau email '
              'halo@meowville.id. Kami menjawab dalam 1x24 jam pada '
              'hari kerja.',
        ],
      ),
    ],
  );

  static const LegalDocument kebijakanKasihSayang = LegalDocument(
    title: 'Kebijakan Kasih Sayang',
    intro:
        'Dokumen ini berisi dua hal: cara kami merawat kucing Anda selama '
        'menginap, dan cara kami memperlakukan data pribadi Anda.',
    status: _draftStatus,
    sections: <LegalSection>[
      LegalSection(
        heading: 'Cara kami merawat kucing Anda',
        points: <String>[
          'Satu kamar untuk satu keluarga kucing. Kucing dari pemilik berbeda '
              'tidak kami satukan.',
          'Makan 2 kali sehari, pukul 08.00 dan 18.00 WIB. Anda boleh '
              'menitipkan makanan sendiri, dan itu yang kami pakai.',
          'Kotak pasir dibersihkan minimal 2 kali sehari, atau setiap kali '
              'kotor.',
          'Waktu main dan interaksi dengan penjaga: minimal 30 menit per '
              'hari.',
          'Kucing yang menolak makan lebih dari 12 jam kami laporkan ke Anda '
              'hari itu juga.',
        ],
      ),
      LegalSection(
        heading: 'Yang tidak kami lakukan',
        points: <String>[
          'Kami tidak memberi obat penenang.',
          'Kami tidak memandikan atau menggunting kuku tanpa permintaan Anda.',
          'Kami tidak memakai foto kucing Anda untuk promosi tanpa izin '
              'tertulis Anda.',
        ],
      ),
      LegalSection(
        heading: 'Data pribadi yang kami simpan',
        paragraphs: <String>[
          'Saat Anda mendaftar dan memesan, kami menyimpan data berikut.',
        ],
        points: <String>[
          'Nama lengkap, alamat email, dan nomor WhatsApp Anda.',
          'Kata sandi Anda dalam bentuk teracak. Kami tidak bisa membacanya.',
          'Data kucing Anda: nama, usia, catatan kesehatan, dan kebiasaan '
              'makan.',
          'Riwayat reservasi dan pembayaran Anda.',
        ],
      ),
      LegalSection(
        heading: 'Untuk apa data itu kami pakai',
        points: <String>[
          'Menghubungi Anda soal reservasi dan kondisi kucing Anda.',
          'Menagih dan mencatat pembayaran.',
          'Memutuskan penanganan saat kucing Anda sakit.',
        ],
        paragraphs: <String>[
          'Kami tidak menjual data Anda, dan tidak mengirim promosi ke nomor '
              'Anda kecuali Anda meminta.',
        ],
      ),
      LegalSection(
        heading: 'Siapa yang bisa melihat data Anda',
        points: <String>[
          'Penjaga dan admin Meowville yang sedang bertugas.',
          'Supabase, sebagai penyedia basis data dan server tempat data ini '
              'tersimpan.',
          'Dokter hewan rujukan, terbatas pada data kesehatan kucing Anda, '
              'dan hanya saat kucing Anda dibawa berobat.',
        ],
      ),
      LegalSection(
        heading: 'Hak Anda atas data Anda',
        points: <String>[
          'Meminta salinan data Anda.',
          'Membetulkan data yang salah.',
          'Meminta akun dan data Anda dihapus. Catatan pembayaran tetap kami '
              'simpan selama 5 tahun untuk keperluan pembukuan, sesuai '
              'praktik umum retensi dokumen keuangan di Indonesia.',
        ],
        paragraphs: <String>[
          'Kirim permintaan ke halo@meowville.id. Kami kerjakan dalam '
              '7 hari kerja.',
        ],
      ),
      LegalSection(
        heading: 'Berapa lama data disimpan',
        paragraphs: <String>[
          'Data akun tersimpan selama akun Anda aktif. Setelah Anda meminta '
              'penghapusan, data kami hapus dalam 30 hari kerja.',
        ],
      ),
      LegalSection(
        heading: 'Kalau terjadi kebocoran data',
        paragraphs: <String>[
          'Kami memberi tahu Anda lewat email dan WhatsApp dalam 3x24 jam '
              'setelah kami mengetahuinya, beserta data apa saja yang '
              'terdampak.',
        ],
      ),
    ],
  );
}