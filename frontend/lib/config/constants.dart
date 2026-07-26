import 'dart:io' show Platform;
import 'dart:math';
import 'dart:ui' show Color, lerpDouble;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static bool _isDark = false;
  static bool get isDark => _isDark;
  static set isDark(bool value) => _isDark = value;

  static const _lightFondo = Color(0xFFF5F0EB);
  static const _lightSuperficie = Color(0xFFE8DCC8);
  static const _lightPrimario = Color(0xFF2D6A4F);
  static const _lightSecundario = Color(0xFFD4A373);
  static const _lightOscuro = Color(0xFF5C4033);
  static const _lightMetalico = Color(0xFFC79A5E);
  static const _lightTexto = Color(0xFF2C1810);
  static const _lightTextoSecundario = Color(0xFF8B7355);
  static const _lightError = Color(0xFFC0392B);
  static const _lightExito = Color(0xFF27AE60);

  static const _darkFondo = Color(0xFF121212);
  static const _darkSuperficie = Color(0xFF1E1E2E);
  static const _darkPrimario = Color(0xFF52B788);
  static const _darkSecundario = Color(0xFFE8B87A);
  static const _darkOscuro = Color(0xFFE8DCC8);
  static const _darkMetalico = Color(0xFFD4A86E);
  static const _darkTexto = Color(0xFFE0E0E0);
  static const _darkTextoSecundario = Color(0xFF9E9E9E);
  static const _darkError = Color(0xFFFF6B6B);
  static const _darkExito = Color(0xFF4ADE80);

  static Color get fondo => _isDark ? _darkFondo : _lightFondo;
  static Color get superficie => _isDark ? _darkSuperficie : _lightSuperficie;
  static Color get primario => _isDark ? _darkPrimario : _lightPrimario;
  static Color get secundario => _isDark ? _darkSecundario : _lightSecundario;
  static Color get oscuro => _isDark ? _darkOscuro : _lightOscuro;
  static Color get metalico => _isDark ? _darkMetalico : _lightMetalico;
  static Color get texto => _isDark ? _darkTexto : _lightTexto;
  static Color get textoSecundario => _isDark ? _darkTextoSecundario : _lightTextoSecundario;
  static Color get error => _isDark ? _darkError : _lightError;
  static Color get exito => _isDark ? _darkExito : _lightExito;

  static LinearGradient get gradienteFondo => _isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF121212), Color(0xFF1A1A2E), Color(0xFF162447)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F0EB), Color(0xFFE8DCC8), Color(0xFFD4E8D0)],
        );
}

class AppConfig {
  static String apiUrl = '';
  static String imageBaseUrl = '';
  static String _customHost = '';
  static int _customPort = 3000;

  static String get host => _customHost;
  static int get port => _customPort;
  static bool get isConfigured => _customHost.isNotEmpty;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _customHost = prefs.getString('server_host') ?? '';
    _customPort = prefs.getInt('server_port') ?? 3000;

    if (_customHost.isNotEmpty) {
      apiUrl = 'http://$_customHost:$_customPort/api';
      imageBaseUrl = 'http://$_customHost:$_customPort';
    } else if (kIsWeb || Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      apiUrl = 'http://localhost:3000/api';
      imageBaseUrl = 'http://localhost:3000';
    } else {
      apiUrl = '';
      imageBaseUrl = '';
    }
  }

  static Future<void> setServer(String host, int port) async {
    _customHost = host;
    _customPort = port;
    apiUrl = 'http://$host:$port/api';
    imageBaseUrl = 'http://$host:$port';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_host', host);
    await prefs.setInt('server_port', port);
  }

  static Future<void> clearServer() async {
    _customHost = '';
    _customPort = 3000;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_host');
    await prefs.remove('server_port');
    await init();
  }
}

class ThemeManager extends ChangeNotifier {
  static ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  static final ThemeManager instance = ThemeManager._();
  ThemeManager._();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode') ?? 'system';
    _mode = _themeModeFromString(saved);
    _updateAppColors();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    _updateAppColors();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _modeToString(mode));
    notifyListeners();
  }

  void _updateAppColors() {
    switch (_mode) {
      case ThemeMode.dark:
        AppColors.isDark = true;
        break;
      case ThemeMode.light:
        AppColors.isDark = false;
        break;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        AppColors.isDark = brightness == Brightness.dark;
        break;
    }
  }

  static ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'dark': return ThemeMode.dark;
      case 'light': return ThemeMode.light;
      default: return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark: return 'dark';
      case ThemeMode.light: return 'light';
      case ThemeMode.system: return 'system';
    }
  }
}
