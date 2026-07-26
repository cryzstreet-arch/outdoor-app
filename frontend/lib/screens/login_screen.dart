import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';
import 'register_screen.dart';
import 'home_screen.dart';

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
        context, MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15, offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.explore,
                          size: 60, color: AppColors.primario),
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
                    icon: Icons.email_outlined,
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
                    icon: Icons.lock_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SkeuomorphicButton(
                    text: 'Entrar',
                    loading: auth.loading,
                    icon: Icons.login,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
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
      ),
    );
  }
}
