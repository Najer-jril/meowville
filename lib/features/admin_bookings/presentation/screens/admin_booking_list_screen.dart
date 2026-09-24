import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/domain/entities/booking_status.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_state_panels.dart';
import '../../../dashboard/presentation/widgets/dashboard_view.dart';
import '../../domain/entities/admin_booking.dart';
import '../../domain/repositories/admin_booking_repository.dart';
import '../../domain/usecases/load_admin_bookings_usecase.dart';
import '../admin_booking_routes.dart';
import '../widgets/admin_booking_card.dart';
import '../widgets/status_filter_chips.dart';

typedef AdminBookingListController = DashboardController<List<AdminBooking>>;

class AdminBookingListScreen extends StatelessWidget {
  const AdminBookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminBookingListController>(
      create: (BuildContext context) => AdminBookingListController(
        LoadAdminBookingsUseCase(context.read<AdminBookingRepository>()).call,
        fallbackMessage:
            'Daftar reservasi gagal dimuat. Coba ulangi sebentar lagi.',
      ),
      child: DashboardView<List<AdminBooking>>(
        loadingLabel: 'Memuat daftar reservasi...',
        errorTitle: 'Daftar reservasi belum bisa dimuat',
        skeletonHeights: const <double>[48, 44, 132, 132, 132],
        builder: (BuildContext context, List<AdminBooking> bookings) =>
            <Widget>[_BookingList(bookings: bookings)],
      ),
    );
  }
}

class _BookingList extends StatefulWidget {
  const _BookingList({required this.bookings});

  final List<AdminBooking> bookings;

  @override
  State<_BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<_BookingList> {
  final TextEditingController _search = TextEditingController();
  BookingStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(AdminBooking booking) async {
    final AdminBookingListController controller = context
        .read<AdminBookingListController>();
    await context.push(AdminBookingRoutes.detail(booking.id));
    await controller.refresh();
  }

  void _clearSearch() {
    _search.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int pendingCount = widget.bookings
        .where((AdminBooking b) => b.status == BookingStatus.pending)
        .length;
    final List<AdminBooking> visible = filterAdminBookings(
      widget.bookings,
      status: _status,
      query: _search.text,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppPageHeader(
          title: 'Reservasi',
          subtitle: pendingCount == 0
              ? 'Tidak ada yang menunggu keputusan Anda.'
              : '$pendingCount reservasi menunggu keputusan Anda.',
        ),
        AppTextField(
          controller: _search,
          hintText: 'Cari nama pawrent atau kucing',
          semanticLabel: 'Cari nama pawrent atau kucing',
          icon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.space12),
        StatusFilterChips(
          selected: _status,
          pendingCount: pendingCount,
          onSelected: (BookingStatus? status) =>
              setState(() => _status = status),
        ),
        const SizedBox(height: AppSpacing.space20),
        if (visible.isEmpty)
          _EmptyState(
            status: _status,
            query: _search.text.trim(),
            onClearSearch: _clearSearch,
          )
        else
          for (int i = 0; i < visible.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.space12),
            AdminBookingCard(
              booking: visible[i],
              onTap: () => _open(visible[i]),
            ),
          ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.status,
    required this.query,
    required this.onClearSearch,
  });

  final BookingStatus? status;
  final String query;
  final VoidCallback onClearSearch;

  static (String, String) _copyFor(BookingStatus? status) => switch (status) {
    null => (
      'Belum ada reservasi',
      'Reservasi yang dibuat pawrent akan muncul di sini.',
    ),
    BookingStatus.pending => (
      'Tidak ada reservasi yang menunggu',
      'Semua permintaan reservasi sudah Anda putuskan.',
    ),
    BookingStatus.confirmed => (
      'Belum ada reservasi dikonfirmasi',
      'Reservasi yang Anda setujui tampil di sini sampai kucingnya check-in.',
    ),
    BookingStatus.checkedIn => (
      'Tidak ada kucing yang sedang menginap',
      'Reservasi pindah ke sini setelah check-in dicatat.',
    ),
    BookingStatus.checkedOut => (
      'Belum ada reservasi selesai',
      'Reservasi pindah ke sini setelah kucing check-out.',
    ),
    BookingStatus.rejected => (
      'Belum ada reservasi ditolak',
      'Reservasi yang Anda tolak tercatat di sini.',
    ),
    BookingStatus.cancelled => (
      'Belum ada reservasi dibatalkan',
      'Reservasi yang dibatalkan pawrent atau admin tercatat di sini.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (query.isNotEmpty) {
      return DashboardEmptyPanel(
        icon: Icons.search_off_rounded,
        title: 'Tidak ada yang cocok dengan "$query"',
        message:
            'Periksa ejaan nama kucing atau pawrent, atau pilih status lain.',
        actionLabel: 'Hapus pencarian',
        onAction: onClearSearch,
      );
    }
    final (String title, String message) = _copyFor(status);
    return DashboardEmptyPanel(
      icon: Icons.event_note_rounded,
      title: title,
      message: message,
    );
  }
}
