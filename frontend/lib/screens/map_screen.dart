import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../config/constants.dart';
import '../models/spot.dart';
import '../providers/spot_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/fog_painter.dart';
import '../widgets/particle_overlay.dart';
import '../widgets/glass_panel.dart';
import '../config/category_themes.dart';
import 'spot_detail_screen.dart';
import '../services/analytics_service.dart';
import '../utils/page_transitions.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _userPosition = const LatLng(-34.6037, -58.3816);
  Position? _gpsPosition;
  StreamSubscription<Position>? _gpsSubscription;
  List<FogSpotData> _fogSpots = [];
  bool _gpsReady = false;
  DateTime _lastSpotLoad = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreen('map');
    _initGps();
    _loadNearbySpots();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Activa el GPS para explorar'),
          backgroundColor: AppColors.error),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).catchError((e) {
      print('GPS initial error: $e');
      return null;
    });

    if (!mounted || pos == null) return;
    setState(() {
      _userPosition = LatLng(pos.latitude, pos.longitude);
      _gpsPosition = pos;
      _gpsReady = true;
    });

    _mapController.move(_userPosition, 14);

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _userPosition = LatLng(pos.latitude, pos.longitude);
        _gpsPosition = pos;
      });
      if (DateTime.now().difference(_lastSpotLoad).inSeconds > 30) {
        _loadNearbySpots();
      }
    }, onError: (e) {
      print('GPS stream error: $e');
    });
  }

  Future<void> _loadNearbySpots() async {
    _lastSpotLoad = DateTime.now();
    final provider = context.read<SpotProvider>();
    final rawSpots = await provider.fetchSpotsRaw();
    if (!mounted) return;

    setState(() {
      _fogSpots = rawSpots.map((s) {
        final spot = Spot.fromJson(s);
        return FogSpotData(
          position: LatLng(spot.lat, spot.lng),
          hideRadius: spot.hideRadius,
          revealRadius: spot.revealRadius,
          detailRadius: spot.detailRadius,
          nombre: spot.nombre,
          categoria: spot.categoria,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ParticleOverlay(
                categoria: _fogSpots.isNotEmpty
                    ? _fogSpots.first.categoria ?? 'otro'
                    : 'otro',
                particleCount: 12,
              ),
            ),
          ),
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition,
              initialZoom: 14,
              onTap: (tapPos, latlng) {
                final tapped = _fogSpots.indexWhere((s) =>
                  const Distance().distance(s.position, latlng) < s.revealRadius);
                if (tapped >= 0) {
                  _openSpotDetail(tapped);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/'
                    'World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.outdoor.app',
              ),
              if (_gpsReady)
                FogPainter(
                  mapController: _mapController,
                  userPosition: _userPosition,
                  spots: _fogSpots,
                  categoria: _nearestCategoria,
                ),
              MarkerLayer(
                markers: [
                  if (_gpsReady)
                    Marker(
                      point: _userPosition,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                          )],
                        ),
                        child: Icon(AppIcons.gps, size: 16, color: AppColors.primario),
                      ),
                    ),
                ],
              ),
            ],
          ),
          _buildInfoOverlay(),
          _buildGpsButton(),
          _buildSpotsNearby(),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16, right: 16,
      child: GlassPanel(
        useBlur: false,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(AppIcons.explorar, color: AppColors.primario, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _gpsReady
                  ? '${_userPosition.latitude.toStringAsFixed(4)}, ${_userPosition.longitude.toStringAsFixed(4)}'
                  : 'Activando GPS...',
              style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
            ),
          ),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gpsReady ? AppColors.exito : AppColors.error,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildGpsButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: GestureDetector(
        onTap: _centerOnUser,
        child: GlassPanel(
          useBlur: false,
          borderRadius: 30,
          padding: const EdgeInsets.all(12),
          shadowEnabled: true,
          child: Icon(AppIcons.gps, color: AppColors.primario, size: 24),
        ),
      ),
    );
  }

  Widget _buildSpotsNearby() {
    final visibles = _fogSpots.where((s) =>
      const Distance().distance(s.position, _userPosition) < s.hideRadius).toList();

    if (visibles.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16, right: 72,
      child: GlassPanel(
        useBlur: false,
        borderRadius: 12,
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Icon(AppIcons.checkin, color: AppColors.secundario, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${visibles.length} spot${visibles.length > 1 ? "s" : ""} cerca',
              style: TextStyle(fontSize: 13, color: AppColors.texto,
                fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  String get _nearestCategoria {
    if (_fogSpots.isEmpty) return 'otro';
    FogSpotData? nearest;
    double minDist = double.infinity;
    for (final s in _fogSpots) {
      final d = const Distance().distance(s.position, _userPosition);
      if (d < minDist) { minDist = d; nearest = s; }
    }
    return nearest?.categoria ?? 'otro';
  }

  void _centerOnUser() {
    _mapController.move(_userPosition, 14);
  }

  void _openSpotDetail(int index) async {
    final spot = _fogSpots[index];
    final dist = const Distance().distance(spot.position, _userPosition);

    if (dist > spot.revealRadius) {
      final restante = ((dist - spot.revealRadius) / 1000).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Faltan $restante km para descubrir este lugar'),
          backgroundColor: AppColors.secundario,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final provider = context.read<SpotProvider>();
    final rawSpots = await provider.fetchSpotsRaw();
    if (!mounted) return;

    for (final s in rawSpots) {
      const epsilon = 0.0001;
      if (((s['lat'] as num).toDouble() - spot.position.latitude).abs() < epsilon &&
          ((s['lng'] as num).toDouble() - spot.position.longitude).abs() < epsilon) {
        Navigator.push(context,
          FadeScaleRoute(page: SpotDetailScreen(spotId: s['id'])));
        break;
      }
    }
  }
}
