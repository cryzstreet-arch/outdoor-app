import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const fondo = Color(0xFFF5F0EB);
  static const superficie = Color(0xFFE8DCC8);
  static const primario = Color(0xFF2D6A4F);
  static const secundario = Color(0xFFD4A373);
  static const oscuro = Color(0xFF5C4033);
  static const metalico = Color(0xFFC79A5E);
  static const texto = Color(0xFF2C1810);
  static const textoSecundario = Color(0xFF8B7355);
  static const error = Color(0xFFC0392B);
  static const exito = Color(0xFF27AE60);

  static const Map<String, List<Color>> categoriaThemes = {
    'senderismo': [Color(0xFF1B4332), Color(0xFF52B788)],
    'pesca': [Color(0xFF023E8A), Color(0xFF90E0EF)],
    'camping': [Color(0xFF6B3A2A), Color(0xFFF4A261)],
    'escalada': [Color(0xFF4A4A4A), Color(0xFFB0A999)],
    'kayak': [Color(0xFF0077B6), Color(0xFFADE8F4)],
    'observacion': [Color(0xFF2B9348), Color(0xFF80ED99)],
    'mirador': [Color(0xFF4A6FA5), Color(0xFFBFC6D4)],
    'natural': [Color(0xFF1B4332), Color(0xFF74C69D)],
    'running': [Color(0xFFE07A00), Color(0xFFFFC300)],
    'otro': [Color(0xFF5C4033), Color(0xFFC79A5E)],
  };
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
