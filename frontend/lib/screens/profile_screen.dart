import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import 'settings_screen.dart';
import '../widgets/glass_panel.dart';
import '../services/analytics_service.dart';
import '../utils/page_transitions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreen('profile');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GlassPanel(
              borderRadius: 100,
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primario.withOpacity(0.1),
                child: const Icon(AppIcons.person, size: 50, color: null),
              ),
            ),
            const SizedBox(height: 12),
            Text(user?.username ?? 'Usuario',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.oscuro,
              ),
            ),
            Text(user?.email ?? '',
              style: TextStyle(fontSize: 14, color: AppColors.textoSecundario),
            ),
            if (user?.estadisticas?.primeActivo == true)
              GlassPanel(
                opacity: 0.15,
                borderRadius: 20,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.star, size: 16, color: null),
                    const SizedBox(width: 4),
                    Text('Prime Activo',
                      style: TextStyle(
                        fontSize: 12, color: AppColors.secundario,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            GlassPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Estadísticas',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.oscuro,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(AppIcons.checkins, '${user?.estadisticas?.totalCheckins ?? 0}', 'Spots'),
                      _statItem(AppIcons.km, '${user?.estadisticas?.totalKm.toStringAsFixed(1) ?? '0'} km', 'Distancia'),
                      _statItem(AppIcons.logros, '${(user?.estadisticas?.totalCheckins ?? 0) ~/ 5}', 'Logros'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.textoSecundario.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _difficultyBadge('Fácil', user?.estadisticas?.totalFacil ?? 0, AppColors.exito),
                      _difficultyBadge('Medio', user?.estadisticas?.totalMedio ?? 0, AppColors.secundario),
                      _difficultyBadge('Difícil', user?.estadisticas?.totalDificil ?? 0, AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                  SlideUpRoute(page: const SettingsScreen())),
                icon: const Icon(AppIcons.configuracion, color: null),
                label: Text('Configuración del servidor',
                  style: TextStyle(color: AppColors.textoSecundario)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.superficie),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.logout(),
                icon: Icon(AppIcons.logout, color: AppColors.error),
                label: Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primario, size: 24),
        const SizedBox(height: 4),
        Text(value,
          style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.oscuro,
          ),
        ),
        Text(label,
          style: TextStyle(fontSize: 12, color: AppColors.textoSecundario),
        ),
      ],
    );
  }

  Widget _difficultyBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 4),
        Text('$count',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oscuro,
          ),
        ),
      ],
    );
  }
}
