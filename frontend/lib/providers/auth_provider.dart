import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;
  String? get error => _error;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _api.setToken(_token);
      try {
        final data = await _api.getPerfil();
        _user = User.fromJson(data);
      } catch (_) {
        _token = null;
        await prefs.remove('token');
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.login(email, password);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }

      _token = data['token'];
      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      final perfilData = await _api.getPerfil();
      _user = User.fromJson(perfilData);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error de conexión';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.register(email, username, password);
      if (data.containsKey('error')) {
        _error = data['error'];
        _loading = false;
        notifyListeners();
        return false;
      }

      _token = data['token'];
      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      final perfilData = await _api.getPerfil();
      _user = User.fromJson(perfilData);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error de conexión';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshPerfil() async {
    if (_token == null) return;
    try {
      final data = await _api.getPerfil();
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
