import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_panel.dart';
import '../widgets/organic_pattern_painter.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../services/analytics_service.dart';
import '../utils/page_transitions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreen('login');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
        context, FadeScaleRoute(page: const HomeScreen()),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradienteFondo,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const OrganicPatternBackground(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassPanel(
                          blurIntensity: 20,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(AppIcons.explorar,
                                size: 60, color: null),
                              const SizedBox(height: 8),
                              Text('Outdoor Social',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primario,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text('Descubre lugares escondidos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        SkeuomorphicTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'tu@email.com',
                          icon: AppIcons.email,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Ingresa tu email';
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
                            if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SkeuomorphicButton(
                          text: 'Entrar',
                          loading: auth.loading,
                          icon: AppIcons.login,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              SlideUpRoute(
                                page: const RegisterScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: AppColors.textoSecundario),
                              children: [
                                const TextSpan(text: '¿No tienes cuenta? '),
                                TextSpan(
                                  text: 'Regístrate',
                                  style: TextStyle(
                                    color: AppColors.primario,
                                    fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
