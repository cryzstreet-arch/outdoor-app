import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';
import 'home_screen.dart';

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
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.oscuro),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
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
                  icon: Icons.email_outlined,
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
                  icon: Icons.person_outlined,
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
                  icon: Icons.lock_outlined,
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
                  icon: Icons.lock_outlined,
                  validator: (v) {
                    if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SkeuomorphicButton(
                  text: 'Crear cuenta',
                  loading: auth.loading,
                  icon: Icons.person_add,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
