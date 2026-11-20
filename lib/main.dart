import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/addon_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/daily_report_controller.dart';
import 'controllers/pet_controller.dart';
import 'controllers/reservation_controller.dart';
import 'controllers/room_controller.dart';
import 'controllers/session_loader.dart';
import 'controllers/settings_controller.dart';
import 'controllers/user_controller.dart';
import 'core/api_client.dart';
import 'core/session_storage.dart';
import 'routes/app_routes.dart';
import 'services/addon_service.dart';
import 'services/auth_service.dart';
import 'services/cat_service.dart';
import 'services/daily_report_service.dart';
import 'services/profile_service.dart';
import 'services/reservation_service.dart';
import 'services/room_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Font dibundel di assets/fonts/google_fonts: tidak ada request ke Google
  // saat runtime, dan tampilan benar walau pertama kali dibuka offline.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  await dotenv.load();

  final api = ApiClient();
  final authService = AuthService(api);
  final profileService = ProfileService(api);
  final storage = StorageService(api);
  final rooms = RoomController(RoomService(api), storage);
  final settings = SettingsController(SettingsService(api))..load();
  final auth = AuthController(
    api,
    authService,
    profileService,
    SessionStorage(),
    storage,
  )..onExpired = _backToLogin;

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storage),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(
          create: (_) => UserController(profileService, authService),
        ),
        ChangeNotifierProvider.value(value: rooms),
        ChangeNotifierProvider(
          create: (_) => AddonController(AddonService(api)),
        ),
        ChangeNotifierProvider(
          create: (_) => PetController(CatService(api), storage),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BookingController(ReservationService(api), storage, rooms),
        ),
        ChangeNotifierProvider(
          create: (_) => ReservationController(ReservationService(api), rooms),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              DailyReportController(DailyReportService(api), storage),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final _navigatorKey = GlobalKey<NavigatorState>();

/// Sesi tidak bisa diperpanjang: bersihkan data layar dan kembali ke login.
void _backToLogin() {
  final context = _navigatorKey.currentContext;
  if (context == null) return;
  resetSessionData(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  _navigatorKey.currentState!.pushNamedAndRemoveUntil(
    AppRoutes.login,
    (_) => false,
  );
  messenger?.showSnackBar(
    const SnackBar(content: Text('Sesi berakhir, silakan login ulang')),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Meowville',
    navigatorKey: _navigatorKey,
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    initialRoute: AppRoutes.splash,
    onGenerateRoute: AppRoutes.generate,
  );
}
