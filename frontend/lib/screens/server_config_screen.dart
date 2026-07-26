import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../widgets/glass_panel.dart';
import '../widgets/organic_pattern_painter.dart';
import 'login_screen.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '3000');
  final _formKey = GlobalKey<FormState>();
  bool _testing = false;
  String? _error;

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _testing = true; _error = null; });

    final ip = _ipCtrl.text.trim();
    final port = int.tryParse(_portCtrl.text.trim()) ?? 3000;

    try {
      final res = await http.get(
        Uri.parse('http://$ip:$port/api/health'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        await AppConfig.setServer(ip, port);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        setState(() { _error = 'Servidor respondió con error ${res.statusCode}'; });
      }
    } catch (e) {
      setState(() { _error = 'No se pudo conectar a $ip:$port'; });
    } finally {
      setState(() { _testing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.gradienteFondo),
        child: Stack(
          children: [
            const Positioned.fill(child: OrganicPatternBackground()),
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
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.explore, size: 60, color: AppColors.primario),
                            const SizedBox(height: 12),
                            Text(
                              'Outdoor Social',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primario,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Conecta con tu servidor',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      GlassPanel(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _ipCtrl,
                              decoration: InputDecoration(
                                labelText: 'IP del servidor',
                                hintText: '192.168.1.100',
                                prefixIcon: Icon(Icons.wifi, color: AppColors.primario),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresa la IP';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _portCtrl,
                              decoration: InputDecoration(
                                labelText: 'Puerto',
                                hintText: '3000',
                                prefixIcon: Icon(Icons.numbers, color: AppColors.primario),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresa el puerto';
                                if (int.tryParse(v) == null) return 'Puerto inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: AppColors.error, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _testing ? null : _connect,
                                icon: _testing
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.wifi_find, color: Colors.white),
                                label: Text(
                                  _testing ? 'Conectando...' : 'Conectar',
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primario,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
