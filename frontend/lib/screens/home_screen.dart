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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final spotProv = context.read<SpotProvider>();
    spotProv.setToken(auth.token);
    spotProv.loadSpots();
    auth.refreshPerfil();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      });
      return const SizedBox.shrink();
    }

    final screens = [
      _FeedTab(),
      const MapScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context, MaterialPageRoute(builder: (_) => const CreateSpotScreen()));
                if (created == true) {
                  context.read<SpotProvider>().loadSpots(refresh: true);
                }
              },
              backgroundColor: AppColors.primario,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.fondo,
          border: Border(top: BorderSide(color: AppColors.superficie, width: 2)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.fondo,
          selectedItemColor: AppColors.primario,
          unselectedItemColor: AppColors.textoSecundario,
          type: BottomNavigationBarType.fixed, elevation: 0,
          selectedFontSize: 12, unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Mapa'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Icon(Icons.explore, color: AppColors.primario, size: 28),
              const SizedBox(width: 8),
              Text('Outdoor Social', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primario)),
              const Spacer(),
              Icon(Icons.notifications_outlined, color: AppColors.textoSecundario, size: 24),
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
                ? Center(child: CircularProgressIndicator(color: AppColors.primario))
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
        MaterialPageRoute(builder: (_) => SpotDetailScreen(spotId: spot.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 150,
              color: AppColors.primario.withOpacity(0.05),
              child: spot.imagenUrl != null
                  ? Image.network('${AppConfig.imageBaseUrl}${spot.imagenUrl}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
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
                Icon(Icons.favorite_border, size: 16, color: AppColors.textoSecundario),
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
                Icon(Icons.location_on_outlined, size: 14, color: AppColors.secundario),
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
    return Center(child: Icon(Icons.landscape, size: 48,
      color: AppColors.textoSecundario.withOpacity(0.2)));
  }
}


