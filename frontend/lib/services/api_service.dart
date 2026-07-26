import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  String get baseUrl => AppConfig.apiUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> register(String email, String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'username': username, 'password': password}),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getPerfil() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/perfil'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getSpots({String? categoria, String? dificultad, int page = 1}) async {
    final params = <String, String>{'page': '$page', 'limit': '20'};
    if (categoria != null) params['categoria'] = categoria;
    if (dificultad != null) params['dificultad'] = dificultad;

    final uri = Uri.parse('$baseUrl/spots').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getSpot(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/spots/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getSpotsCerca(double lat, double lng, {double radio = 5000}) async {
    final uri = Uri.parse('$baseUrl/spots/cerca').replace(queryParameters: {
      'lat': '$lat', 'lng': '$lng', 'radio': '$radio',
    });
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> crearSpot({
    required String nombre,
    required String descripcion,
    required double lat,
    required double lng,
    String categoria = 'otro',
    String dificultad = 'facil',
    double hideRadius = 3000,
    double revealRadius = 1000,
    double detailRadius = 300,
    double gpsRadius = 50,
    double? startLat,
    double? startLng,
    File? imagen,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/spots'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['nombre'] = nombre;
    request.fields['descripcion'] = descripcion;
    request.fields['lat'] = '$lat';
    request.fields['lng'] = '$lng';
    request.fields['categoria'] = categoria;
    request.fields['dificultad'] = dificultad;
    request.fields['hide_radius'] = '$hideRadius';
    request.fields['reveal_radius'] = '$revealRadius';
    request.fields['detail_radius'] = '$detailRadius';
    request.fields['gps_radius'] = '$gpsRadius';
    if (startLat != null) request.fields['start_lat'] = '$startLat';
    if (startLng != null) request.fields['start_lng'] = '$startLng';
    if (imagen != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));
    }

    final stream = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(stream);
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor'};
      } catch (_) {
        return {'error': 'Error del servidor'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> likeSpot(int spotId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/social/spots/$spotId/like'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> comentar(int spotId, String contenido) async {
    final res = await http.post(
      Uri.parse('$baseUrl/social/spots/$spotId/comentarios'),
      headers: _headers,
      body: jsonEncode({'contenido': contenido}),
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getComentarios(int spotId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/social/spots/$spotId/comentarios'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> seguirUsuario(int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/social/usuarios/$userId/seguir'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> checkin(int spotId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/spots/$spotId/checkin'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> publicar(int spotId, File imagen, {String descripcion = ''}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/publicar'));
    request.headers['Authorization'] = 'Bearer $_token';
    request.fields['spot_id'] = '$spotId';
    request.fields['descripcion'] = descripcion;
    request.files.add(await http.MultipartFile.fromPath('imagen', imagen.path));

    final stream = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(stream);
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor'};
      } catch (_) {
        return {'error': 'Error del servidor'};
      }
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getLogros() async {
    final res = await http.get(
      Uri.parse('$baseUrl/logros'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUsuario(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/social/usuarios/$id'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      try {
        final body = jsonDecode(res.body);
        return {'error': body['error'] ?? 'Error del servidor (${res.statusCode})'};
      } catch (_) {
        return {'error': 'Error del servidor (${res.statusCode})'};
      }
    }
    return jsonDecode(res.body);
  }
}
