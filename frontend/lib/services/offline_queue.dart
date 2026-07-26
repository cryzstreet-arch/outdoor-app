import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'api_service.dart';

class QueuedItem {
  final int? id;
  final String tipo;
  final String datos;
  final String? imagenPath;
  final DateTime creado;

  QueuedItem({this.id, required this.tipo, required this.datos, this.imagenPath, DateTime? creado})
      : creado = creado ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipo': tipo,
    'datos': datos,
    'imagen_path': imagenPath,
    'creado': creado.toIso8601String(),
  };

  static QueuedItem fromJson(Map<String, dynamic> j) => QueuedItem(
    id: j['id'] as int?,
    tipo: j['tipo'] as String,
    datos: j['datos'] as String,
    imagenPath: j['imagen_path'] as String?,
    creado: DateTime.parse(j['creado'] as String),
  );
}

class OfflineQueue {
  static Database? _db;
  static final _api = ApiService();

  static Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      p.join(dir.path, 'offline_queue.db'),
      version: 1,
      onCreate: (db, v) => db.execute(
        'CREATE TABLE cola (id INTEGER PRIMARY KEY AUTOINCREMENT, tipo TEXT NOT NULL, datos TEXT NOT NULL, imagen_path TEXT, creado TEXT NOT NULL)'
      ),
    );
    return _db!;
  }

  static Future<void> encolar(String tipo, Map<String, dynamic> datos, {File? imagen}) async {
    final d = await db;
    String? imagenPath;
    if (imagen != null && await imagen.exists()) {
      final dir = await getApplicationDocumentsDirectory();
      final copia = File(p.join(dir.path, 'pending', '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imagen.path)}'));
      await copia.parent.create(recursive: true);
      await imagen.copy(copia.path);
      imagenPath = copia.path;
    }
    await d.insert('cola', {
      'tipo': tipo,
      'datos': jsonEncode(datos),
      'imagen_path': imagenPath,
      'creado': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<QueuedItem>> pendientes() async {
    final d = await db;
    final rows = await d.query('cola', orderBy: 'id ASC');
    return rows.map((r) => QueuedItem.fromJson(r)).toList();
  }

  static Future<void> eliminar(int id) async {
    final d = await db;
    await d.delete('cola', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> sincronizar() async {
    final items = await pendientes();
    if (items.isEmpty) return 0;
    int ok = 0;
    for (final item in items) {
      try {
        final datos = jsonDecode(item.datos) as Map<String, dynamic>;
        if (item.tipo == 'spot') {
          await _api.crearSpot(
            nombre: datos['nombre'],
            descripcion: datos['descripcion'],
            lat: datos['lat'],
            lng: datos['lng'],
            categoria: datos['categoria'] ?? 'otro',
            dificultad: datos['dificultad'] ?? 'facil',
            hideRadius: (datos['hide_radius'] ?? 3000).toDouble(),
            revealRadius: (datos['reveal_radius'] ?? 1000).toDouble(),
            detailRadius: (datos['detail_radius'] ?? 300).toDouble(),
            gpsRadius: (datos['gps_radius'] ?? 50).toDouble(),
            startLat: datos['start_lat']?.toDouble(),
            startLng: datos['start_lng']?.toDouble(),
            imagen: item.imagenPath != null ? File(item.imagenPath!) : null,
          );
        } else if (item.tipo == 'comentario') {
          await _api.comentar(datos['spot_id'], datos['contenido']);
        } else if (item.tipo == 'checkin') {
          await _api.publicar(datos['spot_id'], File(item.imagenPath!), descripcion: datos['descripcion'] ?? '');
        }
        await eliminar(item.id!);
        ok++;
      } catch (_) {}
    }
    return ok;
  }

  static void monitorear() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        sincronizar();
      }
    });
  }

  static Future<bool> hayConexion() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
