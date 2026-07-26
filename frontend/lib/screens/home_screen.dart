import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../models/spot.dart';
import '../providers/auth_provider.dart';
import '../providers/spot_provider.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'spot_detail_screen.dart';
import 'create_spot_screen.dart';
import 'map_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/page_transitions.dart';
import '../widgets/particle_overlay.dart';
import '../config/category_themes.dart';
import '../widgets/glass_panel.dart';
import '../services/analytics_service.dart';
import '../widgets/organic_pattern_painter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreen('home');
    final auth = context.read<AuthProvider>();
    final spotProv = context.read<SpotProvider>();
    spotProv.setToken(auth.token);
    spotProv.loadSpots();
    auth.refreshPerfil();

    _screens = [
      _FeedTab(),
      const MapScreen(),
      const ProfileScreen(),
    ];

    if (AppConfig.apiUrl.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Servidor no configurado. Ve a Perfil → Configuración'),
            backgroundColor: AppColors.secundario,
            duration: const Duration(seconds: 5),
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context, FadeScaleRoute(page: const LoginScreen()));
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.gradienteFondo),
        child: Stack(children: [
          const OrganicPatternBackground(),
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ]),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context, SlideUpRoute(page: const CreateSpotScreen()));
                if (created == true) {
                  context.read<SpotProvider>().loadSpots(refresh: true);
                }
              },
              backgroundColor: AppColors.primario,
              child: const Icon(AppIcons.crear, color: Colors.white),
            )
          : null,
      bottomNavigationBar: GlassPanel(
        useBlur: false,
        borderRadius: 0,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.fondo,
          selectedItemColor: AppColors.primario,
          unselectedItemColor: AppColors.textoSecundario,
          type: BottomNavigationBarType.fixed, elevation: 0,
          selectedFontSize: 12, unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(AppIcons.explorar), label: 'Explorar'),
            BottomNavigationBarItem(icon: Icon(AppIcons.mapa), label: 'Mapa'),
            BottomNavigationBarItem(icon: Icon(AppIcons.perfil), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<SpotProvider>().loadSpots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotProv = context.watch<SpotProvider>();

    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(
            child: ParticleOverlay(categoria: 'natural', particleCount: 10),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  const Icon(AppIcons.explorar, color: null, size: 28),
                  const SizedBox(width: 8),
                  Text('Outdoor Social', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primario)),
                  const Spacer(),
                  const Icon(AppIcons.notificacion, color: null, size: 24),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Spots descubiertos',
                  style: TextStyle(fontSize: 14, color: AppColors.textoSecundario)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: spotProv.spots.isEmpty && spotProv.loading
                    ? const ShimmerCard()
                    : spotProv.spots.isEmpty
                        ? Center(child: Text('No hay spots aún.\n¡Crea el primero!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textoSecundario)))
                        : RefreshIndicator(
                            onRefresh: () => spotProv.loadSpots(refresh: true),
                            child: ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: spotProv.spots.length + (spotProv.loading ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i >= spotProv.spots.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return _SpotCard(spot: spotProv.spots[i]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final Spot spot;
  const _SpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        FadeScaleRoute(page: SpotDetailScreen(spotId: spot.id))),
      child: GlassPanel(
        useBlur: false,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Hero(
              tag: 'spot-img-${spot.id}',
              child: Container(
                height: 150,
                color: AppColors.primario.withOpacity(0.05),
                child: spot.imagenUrl != null
                    ? CachedNetworkImage(
                        imageUrl: '${AppConfig.imageBaseUrl}${spot.imagenUrl}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheWidth: 400,
                        placeholder: (_, __) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primario,
                          ),
                        ),
                        errorWidget: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _tag(spot.categoria, AppColors.primario),
                const SizedBox(width: 6),
                _tag(spot.dificultad,
                  spot.dificultad == 'facil' ? AppColors.exito
                      : spot.dificultad == 'medio' ? AppColors.secundario
                      : AppColors.error),
                const Spacer(),
                const Icon(AppIcons.like, size: 16, color: null),
                const SizedBox(width: 4),
                Text('${spot.totalLikes}', style: TextStyle(
                  fontSize: 12, color: AppColors.textoSecundario)),
              ]),
              const SizedBox(height: 8),
              Text(spot.nombre, style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold, color: AppColors.oscuro)),
              const SizedBox(height: 4),
              Text(spot.descripcion, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: AppColors.textoSecundario)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(AppIcons.checkin, size: 14, color: null),
                const SizedBox(width: 4),
                Text('${spot.lat.toStringAsFixed(2)}, ${spot.lng.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
                const Spacer(),
                Text('@${spot.username ?? "anónimo"}',
                  style: TextStyle(fontSize: 12, color: AppColors.primario)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(
        fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _imgPlaceholder() {
    return Center(child: Icon(AppIcons.mirador, size: 48,
      color: AppColors.textoSecundario.withOpacity(0.2)));
  }
}
