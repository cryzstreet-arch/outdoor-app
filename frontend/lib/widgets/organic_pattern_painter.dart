import 'dart:math';
import 'package:flutter/material.dart';
import '../config/constants.dart';

class OrganicPatternPainter extends CustomPainter {
  final double animationValue;

  OrganicPatternPainter({this.animationValue = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (AppColors.isDark) {
      _paintDark(canvas, size, paint);
    } else {
      _paintLight(canvas, size, paint);
    }
  }

  void _paintLight(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final shift = animationValue * 20;

    paint.color = const Color(0x0A2D6A4F);
    final path1 = Path()
      ..moveTo(0, h * 0.6 + shift)
      ..quadraticBezierTo(w * 0.25, h * 0.45 + shift, w * 0.5, h * 0.55 + shift)
      ..quadraticBezierTo(w * 0.75, h * 0.65 + shift, w, h * 0.5 + shift)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path1, paint);

    paint.color = const Color(0x08D4A373);
    final path2 = Path()
      ..moveTo(0, h * 0.75 - shift * 0.5)
      ..quadraticBezierTo(w * 0.3, h * 0.65 - shift * 0.5, w * 0.6, h * 0.7 - shift * 0.5)
      ..quadraticBezierTo(w * 0.85, h * 0.75 - shift * 0.5, w, h * 0.65 - shift * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, paint);

    paint.color = const Color(0x0652B788);
    final circle1 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.15, h * 0.2 + shift * 0.3),
        radius: w * 0.12,
      ));
    canvas.drawPath(circle1, paint);

    paint.color = const Color(0x05C79A5E);
    final circle2 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.8, h * 0.35 - shift * 0.2),
        radius: w * 0.08,
      ));
    canvas.drawPath(circle2, paint);

    paint.color = const Color(0x041B4332);
    final circle3 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.15 + shift * 0.4),
        radius: w * 0.15,
      ));
    canvas.drawPath(circle3, paint);
  }

  void _paintDark(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final shift = animationValue * 15;

    paint.color = const Color(0x0D52B788);
    final path1 = Path()
      ..moveTo(0, h * 0.55 + shift)
      ..quadraticBezierTo(w * 0.3, h * 0.4 + shift, w * 0.6, h * 0.5 + shift)
      ..quadraticBezierTo(w * 0.85, h * 0.6 + shift, w, h * 0.45 + shift)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path1, paint);

    paint.color = const Color(0x0A7B8FA1);
    final path2 = Path()
      ..moveTo(0, h * 0.7 - shift * 0.5)
      ..quadraticBezierTo(w * 0.4, h * 0.6 - shift * 0.5, w * 0.7, h * 0.65 - shift * 0.5)
      ..lineTo(w, h * 0.55 - shift * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, paint);

    paint.color = const Color(0x080077B6);
    final circle1 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.2, h * 0.25 + shift * 0.3),
        radius: w * 0.1,
      ));
    canvas.drawPath(circle1, paint);

    paint.color = const Color(0x069D4EDD);
    final circle2 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.75, h * 0.3 - shift * 0.2),
        radius: w * 0.13,
      ));
    canvas.drawPath(circle2, paint);

    paint.color = const Color(0x054ADE80);
    final circle3 = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(w * 0.55, h * 0.12 + shift * 0.35),
        radius: w * 0.07,
      ));
    canvas.drawPath(circle3, paint);
  }

  @override
  bool shouldRepaint(covariant OrganicPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class OrganicPatternBackground extends StatefulWidget {
  const OrganicPatternBackground({super.key});

  @override
  State<OrganicPatternBackground> createState() => _OrganicPatternBackgroundState();
}

class _OrganicPatternBackgroundState extends State<OrganicPatternBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    if (reduceMotion || !isCurrent) {
      return Positioned.fill(
        child: CustomPaint(painter: OrganicPatternPainter(animationValue: 0)),
      );
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: OrganicPatternPainter(
              animationValue: _controller.value,
            ),
          );
        },
      ),
    );
  }
}
