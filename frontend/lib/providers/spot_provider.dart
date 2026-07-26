import 'dart:io';
import 'package:flutter/material.dart';
import '../models/spot.dart';
import '../services/api_service.dart';
import '../services/offline_queue.dart';

class SpotProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Spot> _spots = [];
  Spot? _currentSpot;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  List<Map<String, dynamic>> _comentarios = [];

  List<Spot> get spots => _spots;
  Spot? get currentSpot => _currentSpot;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  List<Map<String, dynamic>> get comentarios => _comentarios;

  void setToken(String? token) {
    _api.setToken(token);
  }

  Future<void> loadSpots({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _spots = [];
    }
    if (_loading || !_hasMore) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getSpots(page: _currentPage);
      final spotsList = (data['spots'] as List).map((s) => Spot.fromJson(s)).toList();
      _spots.addAll(spotsList);
      _hasMore = spotsList.length >= 20;
      _currentPage++;
    } catch (e) {
      _error = 'Error al cargar spots';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadSpotDetail(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final spotFuture = _api.getSpot(id);
      final commentsFuture = _api.getComentarios(id);
      final List<dynamic> results = await Future.wait([spotFuture, commentsFuture]);
      _currentSpot = Spot.fromJson(results[0] as Map<String, dynamic>);
      _comentarios = (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = 'Error al cargar spot';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> crearSpot({
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
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (await OfflineQueue.hayConexion()) {
        await _api.crearSpot(
          nombre: nombre,
          descripcion: descripcion,
          lat: lat,
          lng: lng,
          categoria: categoria,
          dificultad: dificultad,
          hideRadius: hideRadius,
          revealRadius: revealRadius,
          detailRadius: detailRadius,
          gpsRadius: gpsRadius,
          startLat: startLat,
          startLng: startLng,
          imagen: imagen,
        );
      } else {
        await OfflineQueue.encolar('spot', {
          'nombre': nombre,
          'descripcion': descripcion,
          'lat': lat,
          'lng': lng,
          'categoria': categoria,
          'dificultad': dificultad,
          'hide_radius': hideRadius,
          'reveal_radius': revealRadius,
          'detail_radius': detailRadius,
          'gps_radius': gpsRadius,
          'start_lat': startLat,
          'start_lng': startLng,
        }, imagen: imagen);
      }
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al crear spot';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> likeSpot(int spotId) async {
    final previousSpot = _currentSpot;
    try {
      final result = await _api.likeSpot(spotId);
      if (_currentSpot != null && _currentSpot!.id == spotId) {
        final newLikes = result['liked'] == true
            ? _currentSpot!.totalLikes + 1
            : _currentSpot!.totalLikes - 1;
        _currentSpot = Spot.fromJson({..._currentSpot!.toJson(), 'total_likes': newLikes});
        notifyListeners();
      }
      return true;
    } catch (_) {
      _currentSpot = previousSpot;
      notifyListeners();
      return false;
    }
  }

  Future<bool> comentar(int spotId, String contenido) async {
    try {
      if (await OfflineQueue.hayConexion()) {
        await _api.comentar(spotId, contenido);
        final raw = await _api.getComentarios(spotId);
        _comentarios = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        await OfflineQueue.encolar('comentario', {'spot_id': spotId, 'contenido': contenido});
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hacerCheckin(int spotId, File foto, {String descripcion = ''}) async {
    try {
      if (await OfflineQueue.hayConexion()) {
        await _api.publicar(spotId, foto, descripcion: descripcion);
        await loadSpotDetail(spotId);
      } else {
        await OfflineQueue.encolar('checkin', {'spot_id': spotId, 'descripcion': descripcion}, imagen: foto);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSpotsRaw() async {
    try {
      final data = await _api.getSpots(page: 1);
      return (data['spots'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  ApiService get api => _api;
}
