abstract final class LegalRoutes {
  static const String ketentuanLayanan = '/legal/ketentuan-layanan';
  static const String kebijakanPrivasi = '/legal/kebijakan-privasi';

  static bool coversLocation(String location) => location.startsWith('/legal');
}
