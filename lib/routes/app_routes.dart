import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_theme.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/policy_screen.dart';
import '../screens/auth/legal_screen.dart';

import '../widgets/app_photo.dart';

import '../screens/admin/addon_form_screen.dart';
import '../screens/admin/addon_list_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/report_screen.dart';
import '../screens/admin/reservation_detail_screen.dart';
import '../screens/admin/room_type_form_screen.dart';
import '../screens/admin/user_create_screen.dart';
import '../screens/admin/user_list_screen.dart';

import '../screens/sitter/sitter_shell.dart';
import '../screens/sitter/booking_detail_screen.dart';
import '../screens/sitter/daily_report_form_screen.dart';

import '../screens/owner/owner_shell.dart';
import '../screens/owner/booking_detail_screen.dart';
import '../screens/owner/pet_form_screen.dart';
import '../screens/owner/pet_detail_screen.dart';
import '../screens/owner/pet_report_screen.dart';
import '../screens/owner/room_detail_screen.dart';
import '../screens/owner/room_catalog_screen.dart';
import '../screens/owner/profile_form_screen.dart';
import '../screens/owner/reservation/reservation_flow_screen.dart';
import '../screens/owner/reservation/reservation_success_screen.dart';

import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const policy = '/policy';
  static const legal = '/legal';

  static const adminHome = '/admin';
  static const adminReservationsDetail = '/admin/reservation-detail';
  static const adminUserCreate = '/admin/user-create';
  static const adminUserList = '/admin/user-list';
  static const adminAddOnList = '/admin/addons';
  static const adminAddOnForm = '/admin/addon-form';
  static const adminRoomTypeForm = '/admin/room-type-form';
  static const adminReport = '/admin/report';

  static const sitterHome = '/sitter';
  static const sitterBookingDetail = '/sitter/booking-detail';
  static const sitterDailyReportForm = '/sitter/daily-report';

  static const ownerHome = '/owner';
  static const ownerPetForm = '/owner/pet-form';
  static const ownerPetDetail = '/owner/pet-detail';
  static const ownerRoomCatalog = '/owner/rooms';
  static const ownerRoomDetail = '/owner/room-detail';
  static const ownerReservationFlow = '/owner/reservation';
  static const ownerReservationSuccess = '/owner/reservation-success';
  static const ownerBookingDetail = '/owner/booking-detail';
  static const ownerPetReport = '/owner/pet-report';
  static const ownerProfileForm = '/owner/profile-form';

  static const photoPreview = '/photo';

  static Route<dynamic> generate(RouteSettings settings) {
    final args = settings.arguments;
    final Widget page = switch (settings.name) {
      splash => const SplashScreen(),
      login => const LoginScreen(),
      register => const RegistrationScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      policy => const PolicyScreen(),
      legal => const LegalScreen(),
      adminHome => const AdminShell(),
      sitterHome => SitterShell(asAdmin: (args as bool?) ?? false),
      ownerHome => const OwnerShell(),
      adminReservationsDetail => ReservationDetailScreen(
        reservation: args as Reservation,
      ),
      adminUserCreate => const UserCreateScreen(),
      adminUserList => const UserListScreen(),
      adminAddOnList => const AddonListScreen(),
      adminAddOnForm => AddonFormScreen(existing: args as Addon?),
      adminRoomTypeForm => RoomTypeFormScreen(existing: args as RoomType?),
      adminReport => const ReportScreen(),
      sitterBookingDetail => SitterBookingDetailScreen(
        reservation: (args as Map)['reservation'] as Reservation,
        actor: args['actor'] as AppUser,
      ),
      sitterDailyReportForm => DailyReportFormScreen(
        reservation: (args as Map)['reservation'] as Reservation,
        actor: args['actor'] as AppUser,
      ),
      ownerPetForm => PetFormScreen(existing: args as Cat?),
      ownerPetDetail => PetDetailScreen(cat: args as Cat),
      ownerRoomCatalog => const RoomCatalogScreen(),
      ownerRoomDetail => RoomDetailScreen(type: args as RoomType),
      ownerReservationFlow => ReservationFlowScreen(
        preselectedType: (args as Map?)?['type'] as RoomType?,
        preselectedCat: args?['cat'] as Cat?,
      ),
      ownerReservationSuccess => ReservationSuccessScreen(
        reservation: args as Reservation,
      ),
      ownerBookingDetail => OwnerBookingDetailScreen(
        reservation: args as Reservation,
      ),
      ownerPetReport => PetReportScreen(reservation: args as Reservation),
      ownerProfileForm => ProfileFormScreen(user: args as AppUser),
      photoPreview => PhotoViewerScreen(
        path: (args as Map)['path'] as String,
        title: args['title'] as String,
      ),
      _ => const _NotFoundScreen(),
    };
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
      fullscreenDialog: settings.name == photoPreview,
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('404', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Halaman tidak ditemukan', style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}