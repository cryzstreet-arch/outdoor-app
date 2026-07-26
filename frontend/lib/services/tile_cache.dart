import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class TileCacheProvider implements TileProvider {
  final String tileUrl;
  TileCacheProvider({this.tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'});

  final _network = OSMNetworkTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    final cached = _getCached(coords);
    if (cached != null) return MemoryImage(cached);
    _descargarYCachear(coords);
    return _network.getImage(coords, options);
  }

  Uint8List? _getCached(TileCoordinates coords) {
    final path = _tilePath(coords);
    final file = File(path);
    if (file.existsSync()) return file.readAsBytesSync();
    return null;
  }

  void _descargarYCachear(TileCoordinates coords) async {
    final url = tileUrl
        .replaceAll('{z}', coords.z.toString())
        .replaceAll('{x}', coords.x.toString())
        .replaceAll('{y}', coords.y.toString());
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final path = _tilePath(coords);
        await File(path).parent.create(recursive: true);
        await File(path).writeAsBytes(res.bodyBytes);
      }
    } catch (_) {}
  }

  String _tilePath(TileCoordinates coords) {
    final dir = _getCacheDir();
    return p.join(dir, '${coords.z}', '${coords.x}', '${coords.y}.png');
  }

  String _getCacheDir() {
    final dir = Directory.systemTemp.path;
    return p.join(dir, 'map_tiles');
  }

  @override
  void dispose() {}
}
