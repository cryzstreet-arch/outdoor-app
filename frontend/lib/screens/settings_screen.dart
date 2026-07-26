import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: AppConfig.host);
    _portCtrl = TextEditingController(text: AppConfig.port.toString());
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.superficie,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.oscuro),
        title: Text('Configuración del Servidor',
          style: TextStyle(color: AppColors.oscuro, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.dns, size: 48, color: AppColors.primario),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Conecta tu app al servidor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.oscuro)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppConfig.isConfigured
                      ? 'Conectado a: ${AppConfig.host}:${AppConfig.port}'
                      : 'Sin configurar - usa auto-detección',
                  style: TextStyle(fontSize: 13, color: AppColors.textoSecundario)),
              ),
              const SizedBox(height: 32),
              SkeuomorphicTextField(
                controller: _hostCtrl,
                label: 'Dirección del servidor (IP o hostname)',
                hint: '192.168.1.100',
                icon: Icons.dns,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la dirección del servidor';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SkeuomorphicTextField(
                controller: _portCtrl,
                label: 'Puerto',
                hint: '3000',
                icon: Icons.numbers,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el puerto';
                  if (int.tryParse(v) == null) return 'Puerto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: SkeuomorphicButton(
                  text: 'Guardar y conectar',
                  icon: Icons.save,
                  onPressed: _save,
                ),
              ),
              if (AppConfig.isConfigured) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SkeuomorphicButton(
                    text: 'Restablecer (auto-detectar)',
                    icon: Icons.restart_alt,
                    color: AppColors.secundario,
                    onPressed: _reset,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.superficie.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cómo funciona?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.oscuro)),
                    const SizedBox(height: 8),
                    Text(
                      '1. Inicia el servidor en tu computadora con start_server.sh\n'
                      '2. Escribe la IP de tu computadora en la red local\n'
                      '3. El servidor debe estar en el mismo WiFi que tu celular\n\n'
                      'Si dejas los campos vacíos, la app intentará auto-detectar el servidor.',
                      style: TextStyle(fontSize: 12, color: AppColors.textoSecundario,
                        height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final host = _hostCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 3000;
    await AppConfig.setServer(host, port);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Servidor configurado: $host:$port'),
      backgroundColor: AppColors.exito));
    Navigator.pop(context);
  }

  void _reset() async {
    await AppConfig.clearServer();
    if (!mounted) return;
    setState(() {
      _hostCtrl.text = '';
      _portCtrl.text = '3000';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Restablecido a auto-detección'),
      backgroundColor: AppColors.secundario));
  }
}
