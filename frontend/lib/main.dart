import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/spot_provider.dart';
import 'services/discovery_service.dart';
import 'services/offline_queue.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  if (!AppConfig.isConfigured) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final result = await DiscoveryService.discoverServer();
      if (result != null) {
        AppConfig.setServer(result.ip, result.port);
      }
    }
  }

  OfflineQueue.monitorear();
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
      ],
      child: MaterialApp(
        title: 'Outdoor Social',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: AppColors.primario,
            secondary: AppColors.secundario,
            surface: AppColors.fondo,
            error: AppColors.error,
          ),
          scaffoldBackgroundColor: AppColors.fondo,
          fontFamily: 'Roboto',
        ),
        home: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            if (auth.loading) {
              return Scaffold(
                backgroundColor: AppColors.fondo,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, size: 80, color: AppColors.primario),
                      const SizedBox(height: 16),
                      Text('Outdoor Social',
                        style: TextStyle(fontSize: 24,
                          fontWeight: FontWeight.bold, color: AppColors.primario),
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(color: AppColors.primario),
                    ],
                  ),
                ),
              );
            }
            return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
