import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import '../providers/spot_provider.dart';
import '../widgets/skeuomorphic_button.dart';
import '../widgets/skeuomorphic_text_field.dart';
import '../widgets/glass_panel.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/organic_pattern_painter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/analytics_service.dart';

class CreateSpotScreen extends StatefulWidget {
  const CreateSpotScreen({super.key});
  @override
  State<CreateSpotScreen> createState() => _CreateSpotScreenState();
}

class _CreateSpotScreenState extends State<CreateSpotScreen> {
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _imagen;
  String _categoria = 'pesca';
  String _dificultad = 'facil';
  double _hideRadius = 3000;
  double _revealRadius = 1000;
  double _detailRadius = 300;
  double _gpsRadius = 50;
  double? _startLat;
  double? _startLng;

  // Mock coordinates (en producción usar GPS del teléfono)
  double _lat = -34.6037;
  double _lng = -58.3816;

  @override
  void initState() {
    super.initState();
    AnalyticsService().trackScreen('create_spot');
    _initGps();
  }

  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (_) {}
  }

  final List<String> _categorias = [
    'pesca', 'senderismo', 'camping', 'running',
    'escalada', 'kayak', 'observacion', 'otro'
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spotProv = context.watch<SpotProvider>();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: GlassAppBar(title: 'Nuevo Spot'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.fondo, AppColors.fondo],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: OrganicPatternBackground()),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _tomarFoto,
                child: GlassPanel(
                  borderRadius: 12,
                  shadowEnabled: false,
                  child: _imagen != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imagen!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 48,
                              color: AppColors.textoSecundario.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text('Tocar para agregar foto',
                              style: TextStyle(color: AppColors.textoSecundario)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              SkeuomorphicTextField(
                controller: _nombreCtrl,
                label: 'Nombre del lugar',
                hint: 'Ej: Río Escondido',
                icon: Icons.edit_location_alt,
                validator: (v) => (v == null || v.isEmpty) ? 'Nombre requerido' : null,
              ),
              const SizedBox(height: 16),
              SkeuomorphicTextField(
                controller: _descCtrl,
                label: 'Descripción',
                hint: 'Describe el lugar, cómo llegar, qué encontrarás...',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 20),
              Text('Categoría', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.oscuro)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categorias.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.toUpperCase(), style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: _categoria == cat ? Colors.white : AppColors.textoSecundario)),
                      selected: _categoria == cat,
                      selectedColor: AppColors.primario,
                      backgroundColor: AppColors.superficie,
                      onSelected: (_) => setState(() => _categoria = cat),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Text('Dificultad', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.oscuro)),
              const SizedBox(height: 8),
              Row(children: [
                _difChip('facil', AppColors.exito),
                const SizedBox(width: 8),
                _difChip('medio', AppColors.secundario),
                const SizedBox(width: 8),
                _difChip('dificil', AppColors.error),
              ]),
              const SizedBox(height: 20),
              Text('Radios de ocultamiento (metros)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.oscuro)),
              const SizedBox(height: 8),
              _radiusSlider('Oculto (> m)', _hideRadius, 500, 5000, (v) => _hideRadius = v),
              _radiusSlider('Nombre (< m)', _revealRadius, 100, 3000, (v) => _revealRadius = v),
              _radiusSlider('Detalle (< m)', _detailRadius, 50, 1000, (v) => _detailRadius = v),
              _radiusSlider('GPS validar (< m)', _gpsRadius, 10, 500, (v) => _gpsRadius = v),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: SkeuomorphicButton(
                  text: 'Publicar Spot',
                  icon: Icons.add_location_alt,
                  loading: spotProv.loading,
                  onPressed: _crearSpot,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ],
    ),
  ),
);
  }

  Widget _difChip(String label, Color color) {
    final selected = _dificultad == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dificultad = label),
        child: GlassPanel(
          opacity: selected ? 0.15 : 0.08,
          borderRadius: 10,
          shadowEnabled: false,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: selected ? color : AppColors.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }

  Widget _radiusSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label,
          style: TextStyle(fontSize: 12, color: AppColors.textoSecundario))),
        Expanded(
          child: Slider(
            value: value, min: min, max: max,
            activeColor: AppColors.primario,
            inactiveColor: AppColors.superficie,
            divisions: 20,
            label: '${value.toInt()} m',
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 50, child: Text('${value.toInt()} m',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.oscuro))),
      ]),
    );
  }

  void _tomarFoto() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondo,
        title: Text('Agregar foto',
          style: TextStyle(color: AppColors.oscuro)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primario),
              title: Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primario),
              title: Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      final photo = await picker.pickImage(source: source);
      if (photo != null) setState(() => _imagen = File(photo.path));
    }
  }

  void _crearSpot() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagen == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Agrega una foto del lugar'),
        backgroundColor: AppColors.error));
      return;
    }

    final ok = await context.read<SpotProvider>().crearSpot(
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      lat: _lat,
      lng: _lng,
      categoria: _categoria,
      dificultad: _dificultad,
      hideRadius: _hideRadius,
      revealRadius: _revealRadius,
      detailRadius: _detailRadius,
      gpsRadius: _gpsRadius,
      imagen: _imagen,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('¡Spot creado exitosamente!'),
        backgroundColor: AppColors.exito));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<SpotProvider>().error ?? 'Error'),
        backgroundColor: AppColors.error));
    }
  }
}
