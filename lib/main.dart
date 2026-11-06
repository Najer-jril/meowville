import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/user_controller.dart';
import 'core/api_client.dart';
import 'core/session_storage.dart';
import 'data/data.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final api = ApiClient();
  final authService = AuthService(api);
  final profileService = ProfileService(api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(
            api,
            authService,
            profileService,
            SessionStorage(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UserController(profileService, authService),
        ),
        ChangeNotifierProvider(create: (_) => AdminStore()),
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
