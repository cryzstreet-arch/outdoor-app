import 'dart:io' show Platform;
import 'dart:ui' show Color;

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
}

class AppConfig {
  static const networkApiUrl = 'http://10.108.9.226:3000/api';
  static String get networkImageBaseUrl => 'http://10.108.9.226:3000';

  static String get fallbackApiUrl => Platform.isLinux ? 'http://localhost:3000/api' : networkApiUrl;
  static String get fallbackImageBaseUrl => Platform.isLinux ? 'http://localhost:3000' : networkImageBaseUrl;

  static String apiUrl = fallbackApiUrl;
  static String imageBaseUrl = fallbackImageBaseUrl;

  static void setServer(String ip, int port) {
    apiUrl = 'http://$ip:$port/api';
    imageBaseUrl = 'http://$ip:$port';
  }
}
