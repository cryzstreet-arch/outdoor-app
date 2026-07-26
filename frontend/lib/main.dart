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
import 'widgets/organic_pattern_painter.dart';

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

  runApp(OutdoorApp());
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
                primary: AppColors._lightPrimario,
                secondary: AppColors._lightSecundario,
                surface: AppColors._lightFondo,
                error: AppColors._lightError,
              ),
              scaffoldBackgroundColor: AppColors._lightFondo,
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
                primary: AppColors._darkPrimario,
                secondary: AppColors._darkSecundario,
                surface: AppColors._darkFondo,
                error: AppColors._darkError,
              ),
              scaffoldBackgroundColor: AppColors._darkFondo,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
            home: Consumer<AuthProvider>(
              builder: (_, auth, __) {
                if (auth.loading) {
                  return _buildLoadingScreen();
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.gradienteFondo),
        child: Stack(
          children: [
            const Positioned.fill(child: OrganicPatternBackground()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.explore, size: 80, color: AppColors.primario),
                  const SizedBox(height: 16),
                  Text(
                    'Outdoor Social',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primario,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.primario),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
