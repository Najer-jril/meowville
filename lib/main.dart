import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'controllers/addon_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/daily_report_controller.dart';
import 'controllers/pet_controller.dart';
import 'controllers/reservation_controller.dart';
import 'controllers/room_controller.dart';
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
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final api = ApiClient();
  final authService = AuthService(api);
  final profileService = ProfileService(api);
  final storage = StorageService(api);
  final rooms = RoomController(RoomService(api), storage);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storage),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            api,
            authService,
            profileService,
            SessionStorage(),
            storage,
          ),
        ),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Meowville',
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    initialRoute: AppRoutes.splash,
    onGenerateRoute: AppRoutes.generate,
  );
}
