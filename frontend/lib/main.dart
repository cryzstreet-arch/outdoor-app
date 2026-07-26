import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/spot_provider.dart';
import 'services/discovery_service.dart';
import 'services/offline_queue.dart';
import 'services/analytics_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/server_config_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  await ThemeManager.instance.init();

  if (!AppConfig.isConfigured) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      DiscoveryService.discoverServer().then((result) {
        if (result != null) {
          AppConfig.setServer(result.ip, result.port);
        }
      }).catchError((_) {});
    }
  }

  OfflineQueue.monitorear();
  AnalyticsService().init();
  OfflineQueue.sincronizar().catchError((_) {});

  runApp(const OutdoorApp());
}

class OutdoorApp extends StatelessWidget {
  const OutdoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => SpotProvider()),
        ChangeNotifierProvider.value(value: ThemeManager.instance),
      ],
      child: ListenableBuilder(
        listenable: ThemeManager.instance,
        builder: (context, _) {
          return MaterialApp(
            title: 'Outdoor Social',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeManager.instance.mode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF2D6A4F),
                secondary: const Color(0xFFD4A373),
                surface: const Color(0xFFF5F0EB),
                error: const Color(0xFFC0392B),
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F0EB),
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: const Color(0xFF52B788),
                secondary: const Color(0xFFE8B87A),
                surface: const Color(0xFF121212),
                error: const Color(0xFFFF6B6B),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
            home: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                if (auth.loading) {
                  return const SplashScreen();
                }
                if (!AppConfig.isConfigured) {
                  return const ServerConfigScreen();
                }
                return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
