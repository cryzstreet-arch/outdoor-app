import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FogPainter extends StatelessWidget {
  final MapController mapController;
  final LatLng userPosition;
  final List<FogSpotData> spots;

  const FogPainter({
    required this.mapController,
    required this.userPosition,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FogCustomPainter(
        mapController: mapController,
        userPosition: userPosition,
        spots: spots,
      ),
      size: Size.infinite,
    );
  }
}

class FogSpotData {
  final LatLng position;
  final double hideRadius;
  final double revealRadius;
  final double detailRadius;
  final String? nombre;
  final String? categoria;

  FogSpotData({
    required this.position,
    required this.hideRadius,
    required this.revealRadius,
    required this.detailRadius,
    this.nombre,
    this.categoria,
  });
}

class _FogCustomPainter extends CustomPainter {
  final MapController mapController;
  final LatLng userPosition;
  final List<FogSpotData> spots;

  _FogCustomPainter({
    required this.mapController,
    required this.userPosition,
    required this.spots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fogColor = const Color(0xFF0D1B2A).withOpacity(0.55);

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = fogColor);

    final clearPaint = Paint()..blendMode = BlendMode.dstOut;

    final userScreen = _toScreen(userPosition, size);
    if (userScreen != null) {
      _drawClearArea(canvas, userScreen, size.width * 0.5, clearPaint);
    }

    for (final spot in spots) {
      final spotScreen = _toScreen(spot.position, size);
      if (spotScreen == null) continue;

      final dist = const Distance().distance(userPosition, spot.position);
      double clearRadius;

      if (dist <= spot.detailRadius) {
        clearRadius = 80;
      } else if (dist <= spot.revealRadius) {
        clearRadius = 40;
      } else if (dist <= spot.hideRadius) {
        clearRadius = 20;
      } else {
        continue;
      }

      _drawClearArea(canvas, spotScreen, clearRadius, clearPaint);
      _drawSpotMarker(canvas, spotScreen, dist, spot, size);
    }

    canvas.restore();
  }

  void _drawClearArea(Canvas canvas, Offset center, double radius, Paint clearPaint) {
    final shader = ui.Gradient.radial(
      center,
      radius,
      [Colors.black, Colors.transparent],
      [0.3, 1.0],
      TileMode.clamp,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = shader..blendMode = BlendMode.dstOut,
    );
  }

  void _drawSpotMarker(Canvas canvas, Offset center, double dist, FogSpotData spot, Size size) {
    if (dist <= spot.hideRadius) {
      final alpha = dist <= spot.detailRadius ? 220 : 120;

      if (dist <= spot.revealRadius) {
        canvas.drawCircle(center, 4, Paint()..color = Color.fromARGB(alpha, 46, 106, 79));
        canvas.drawCircle(center, 10, Paint()
          ..color = Color.fromARGB(alpha ~/ 3, 46, 106, 79)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      } else {
        canvas.drawCircle(center, 3, Paint()..color = Color.fromARGB(80, 180, 180, 180));
      }
    }
  }

  Offset? _toScreen(LatLng point, Size size) {
    try {
      final camera = mapController.camera;
      final screenPoint = camera.latLngToScreenPoint(point);
      return Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
    } catch (_) {
      return null;
    }
  }

  @override
  bool shouldRepaint(_FogCustomPainter oldDelegate) => true;
}
