import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import '../models/spot.dart';
import '../providers/spot_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';

class SpotDetailScreen extends StatefulWidget {
  final int spotId;
  const SpotDetailScreen({super.key, required this.spotId});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  final _comentarioCtrl = TextEditingController();
  File? _fotoCheckin;

  @override
  void initState() {
    super.initState();
    context.read<SpotProvider>().loadSpotDetail(widget.spotId);
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spotProv = context.watch<SpotProvider>();
    final spot = spotProv.currentSpot;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.superficie,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.oscuro),
        title: Text(spot?.nombre ?? 'Detalle',
          style: TextStyle(color: AppColors.oscuro, fontSize: 18),
        ),
      ),
      body: spotProv.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primario))
          : spot == null
              ? Center(child: Text('Spot no encontrado',
                  style: TextStyle(color: AppColors.textoSecundario)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImage(spot),
                      const SizedBox(height: 16),
                      _buildHeader(spot),
                      const SizedBox(height: 12),
                      _buildInfo(spot),
                      const SizedBox(height: 16),
                      _buildDescription(spot),
                      const SizedBox(height: 16),
                      _buildStats(spot),
                      const SizedBox(height: 20),
                      _buildActions(spot),
                      const SizedBox(height: 20),
                      _buildComentariosSection(spot, spotProv),
                    ],
                  ),
                ),
    );
  }

  Widget _buildImage(Spot spot) {
    return Container(
      height: 200, width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: spot.imagenUrl != null
            ? Image.network('${AppConfig.imageBaseUrl}${spot.imagenUrl}',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(child: Icon(Icons.landscape, size: 64,
      color: AppColors.textoSecundario.withOpacity(0.3)));
  }

  Widget _buildHeader(Spot spot) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(spot.nombre, style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.bold, color: AppColors.oscuro)),
          const SizedBox(height: 4),
          Text('@${spot.username ?? "anónimo"}',
            style: TextStyle(fontSize: 13, color: AppColors.primario)),
        ]),
      ),
      _chip(spot.categoria, AppColors.primario),
      const SizedBox(width: 8),
      _chip(spot.dificultad,
        spot.dificultad == 'facil' ? AppColors.exito
            : spot.dificultad == 'medio' ? AppColors.secundario
            : AppColors.error),
    ]);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(
        fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildInfo(Spot spot) {
    return Row(children: [
      Icon(Icons.location_on_outlined, size: 16, color: AppColors.secundario),
      const SizedBox(width: 4),
      Text('${spot.lat.toStringAsFixed(4)}, ${spot.lng.toStringAsFixed(4)}',
        style: TextStyle(fontSize: 13, color: AppColors.textoSecundario)),
    ]);
  }

  Widget _buildDescription(Spot spot) {
    return Text(spot.descripcion.isNotEmpty ? spot.descripcion : 'Sin descripción',
      style: TextStyle(fontSize: 14, color: AppColors.texto, height: 1.5));
  }

  Widget _buildStats(Spot spot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statCol(Icons.favorite_border, '${spot.totalLikes}', 'Likes'),
        _statCol(Icons.chat_bubble_outline, '${spot.totalComentarios}', 'Comentarios'),
        _statCol(Icons.check_circle_outline, '${spot.totalCheckins}', 'Visitas'),
      ]),
    );
  }

  Widget _statCol(IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: AppColors.primario, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold,
        color: AppColors.oscuro, fontSize: 16)),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textoSecundario)),
    ]);
  }

  Widget _buildActions(Spot spot) {
    return Column(children: [
      Row(children: [
        Expanded(
          child: SkeuomorphicButton(
            text: '❤️ Like',
            icon: Icons.favorite_border,
            onPressed: () => context.read<SpotProvider>().likeSpot(spot.id),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SkeuomorphicButton(
            text: '📸 Check-in',
            icon: Icons.camera_alt,
            color: AppColors.secundario,
            onPressed: _tomarFoto,
          ),
        ),
      ]),
      if (_fotoCheckin != null) ...[
        const SizedBox(height: 12),
        Container(
          height: 80, width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(_fotoCheckin!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        SkeuomorphicButton(
          text: 'Publicar y ganar progreso',
          icon: Icons.check_circle,
          color: AppColors.exito,
          onPressed: _publicarCheckin,
        ),
      ],
    ]);
  }

  void _tomarFoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) setState(() => _fotoCheckin = File(photo.path));
  }

  void _publicarCheckin() async {
    if (_fotoCheckin == null || _currentSpot() == null) return;
    final ok = await context.read<SpotProvider>()
        .hacerCheckin(_currentSpot()!.id, _fotoCheckin!);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('¡Descubrimiento registrado!'),
        backgroundColor: AppColors.exito));
      setState(() => _fotoCheckin = null);
    }
  }

  Spot? _currentSpot() => context.read<SpotProvider>().currentSpot;

  Widget _buildComentariosSection(Spot spot, SpotProvider spotProv) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Comentarios', style: TextStyle(fontSize: 16,
        fontWeight: FontWeight.bold, color: AppColors.oscuro)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.fondo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.superficie),
            ),
            child: TextField(
              controller: _comentarioCtrl,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.send, color: AppColors.primario),
          onPressed: () async {
            if (_comentarioCtrl.text.trim().isEmpty) return;
            await spotProv.comentar(spot.id, _comentarioCtrl.text.trim());
            _comentarioCtrl.clear();
          },
        ),
      ]),
      const SizedBox(height: 12),
      ...spotProv.comentarios.map((c) => _comentarioItem(c)),
    ]);
  }

  Widget _comentarioItem(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.superficie.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('@${c['username'] ?? "usuario"}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.primario)),
          const Spacer(),
          Text(c['created_at']?.toString().substring(0, 10) ?? '',
            style: TextStyle(fontSize: 10, color: AppColors.textoSecundario)),
        ]),
        const SizedBox(height: 4),
        Text(c['contenido'] ?? '',
          style: TextStyle(fontSize: 13, color: AppColors.texto)),
      ]),
    );
  }
}
