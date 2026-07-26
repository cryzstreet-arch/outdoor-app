import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_panel.dart';
import '../widgets/organic_pattern_painter.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';
import 'home_screen.dart';
import '../services/analytics_service.dart';
import '../utils/page_transitions.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreen('register');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _emailCtrl.text.trim(),
      _userCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        FadeScaleRoute(page: const HomeScreen()),
        (route) => false,
      );
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: const GlassAppBar(title: 'Registro'),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradienteFondo,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const OrganicPatternBackground(),
              SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassPanel(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Crear cuenta',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primario,
                              ),
                            ),
                            Text('Únete a la comunidad outdoor',
                              style: TextStyle(
                                fontSize: 14, color: AppColors.textoSecundario,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SkeuomorphicTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              hint: 'tu@email.com',
                              icon: AppIcons.email,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email requerido';
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SkeuomorphicTextField(
                              controller: _userCtrl,
                              label: 'Nombre de usuario',
                              hint: 'explorador123',
                              icon: AppIcons.person,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Usuario requerido';
                                if (v.length < 3) return 'Mínimo 3 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SkeuomorphicTextField(
                              controller: _passCtrl,
                              label: 'Contraseña',
                              hint: '••••••',
                              obscure: true,
                              icon: AppIcons.lock,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Contraseña requerida';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SkeuomorphicTextField(
                              controller: _confirmCtrl,
                              label: 'Confirmar contraseña',
                              hint: '••••••',
                              obscure: true,
                              icon: AppIcons.lock,
                              validator: (v) {
                                if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            SkeuomorphicButton(
                              text: 'Crear cuenta',
                              loading: auth.loading,
                              icon: AppIcons.registrar,
                              onPressed: _register,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
