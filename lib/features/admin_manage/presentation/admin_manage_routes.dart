abstract final class AdminManageRoutes {
  static const String hub = '/admin/kelola';

  static const String staffSegment = 'staf';
  static const String staff = '$hub/$staffSegment';
  static const String createStaffSegment = 'baru';
  static const String createStaff = '$staff/$createStaffSegment';

  static const String addOnsSegment = 'layanan';
  static const String addOns = '$hub/$addOnsSegment';
  static const String reportSegment = 'laporan';
  static const String report = '$hub/$reportSegment';
}
