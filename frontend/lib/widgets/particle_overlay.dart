import 'dart:math';
import 'package:flutter/material.dart';
import '../config/category_themes.dart';

class ParticleOverlay extends StatefulWidget {
  final String categoria;
  final int particleCount;

  const ParticleOverlay({
    super.key,
    required this.categoria,
    this.particleCount = 15,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = List.generate(widget.particleCount, (_) => _createParticle());
  }

  Particle _createParticle() {
    final theme = CategoryTheme.forCategoria(widget.categoria);
    return Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 2 + _random.nextDouble() * 4,
      speed: 0.0002 + _random.nextDouble() * 0.0008,
      opacity: 0.2 + _random.nextDouble() * 0.5,
      color: theme.particleColor,
      phase: _random.nextDouble() * 2 * pi,
      wobble: 0.5 + _random.nextDouble() * 2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CategoryTheme.forCategoria(widget.categoria);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    if (reduceMotion || !isCurrent) {
      return Positioned.fill(
        child: CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: 0.0,
            particleType: theme.particleType,
          ),
          size: Size.infinite,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            particleType: theme.particleType,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x, y, size, speed, opacity, phase, wobble;
  Color color;
  Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.color,
    required this.phase, required this.wobble,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final String particleType;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.particleType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withOpacity(p.opacity);

      switch (particleType) {
        case 'leaves':
          _drawLeaf(canvas, size, p, paint);
          break;
        case 'bubbles':
          _drawBubble(canvas, size, p, paint);
          break;
        case 'fireflies':
          _drawFirefly(canvas, size, p, paint);
          break;
        case 'dust':
          _drawDust(canvas, size, p, paint);
          break;
        case 'waves':
          _drawWave(canvas, size, p, paint);
          break;
        case 'feathers':
          _drawFeather(canvas, size, p, paint);
          break;
        case 'mist':
          _drawMist(canvas, size, p, paint);
          break;
        case 'sparks':
        default:
          _drawSpark(canvas, size, p, paint);
          break;
      }
    }
  }

  void _drawLeaf(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = p.x * size.width + sin(t * 2 * pi * p.wobble) * 20;
    final y = (p.y + t * p.speed * 500) % 1.1 * size.height;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(t * 2 * pi * 0.3 + p.phase);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: p.size * 3, height: p.size),
      paint,
    );
    canvas.restore();
  }

  void _drawBubble(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = p.x * size.width + sin(t * 4 * pi) * 10;
    final y = (1.1 - t) * size.height * (0.5 + p.speed * 200);
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(x, y),
      p.size * 1.5,
      paint..color = p.color.withOpacity(p.opacity * opacity),
    );
    canvas.drawCircle(
      Offset(x, y),
      p.size * 1.5,
      Paint()
        ..color = Colors.white.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  void _drawFirefly(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = p.x * size.width + sin(t * 6 * pi * p.wobble) * 30;
    final y = p.y * size.height + cos(t * 4 * pi) * 20;
    final glow = (sin(t * 8 * pi) + 1) / 2;
    final radius = p.size * (1 + glow * 2);
    final gradient = RadialGradient(
      colors: [
        p.color.withOpacity(p.opacity * glow),
        p.color.withOpacity(0),
      ],
    );
    canvas.drawCircle(
      Offset(x, y),
      radius,
      paint..shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: radius)),
    );
  }

  void _drawDust(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = p.x * size.width + sin(t * 3 * pi * p.wobble) * 15;
    final y = (p.y + t * p.speed * 100) % 1.1 * size.height;
    canvas.drawCircle(Offset(x, y), p.size * 0.5, paint);
  }

  void _drawWave(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final path = Path();
    final y = p.y * size.height;
    path.moveTo(0, y);
    for (double x = 0; x <= size.width; x += 2) {
      final wave = sin((x / size.width * 4 * pi) + t * 2 * pi) * p.size * 3;
      path.lineTo(x, y + wave);
    }
    canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawFeather(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = p.x * size.width + sin(t * 2 * pi * p.wobble) * 25;
    final y = (p.y + t * p.speed * 300) % 1.1 * size.height;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(sin(t * 2 * pi) * 0.3);
    final path = Path()
      ..moveTo(0, -p.size * 2)
      ..quadraticBezierTo(p.size, -p.size, 0, p.size * 2)
      ..quadraticBezierTo(-p.size, -p.size, 0, -p.size * 2);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawMist(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = (p.x + t * p.speed * 200) % 1.2 * size.width;
    final y = p.y * size.height;
    final gradient = RadialGradient(
      colors: [
        p.color.withOpacity(p.opacity * 0.3),
        p.color.withOpacity(0),
      ],
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y),
        width: p.size * 20,
        height: p.size * 8,
      ),
      paint..shader = gradient.createShader(
        Rect.fromCenter(
          center: Offset(x, y),
          width: p.size * 20,
          height: p.size * 8)),
    );
  }

  void _drawSpark(Canvas canvas, Size size, Particle p, Paint paint) {
    final t = (progress + p.phase / (2 * pi)) % 1.0;
    final x = p.x * size.width + sin(t * 5 * pi) * 8;
    final y = (1.0 - t) * size.height;
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(x, y),
      p.size * opacity,
      paint..color = p.color.withOpacity(p.opacity * opacity),
    );
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
