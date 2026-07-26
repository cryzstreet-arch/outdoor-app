import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/constants.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurIntensity;
  final double? opacity;
  final double? borderOpacity;
  final bool shadowEnabled;
  final bool useBlur;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurIntensity = 12,
    this.opacity,
    this.borderOpacity,
    this.shadowEnabled = true,
    this.useBlur = true,
    this.color,
    this.padding,
    this.margin,
    this.constraints,
  });

  double get _bgOpacity => opacity ?? (AppColors.isDark ? 0.45 : 0.12);
  double get _borderOp => borderOpacity ?? (AppColors.isDark ? 0.15 : 0.25);
  Color get _bgColor {
    if (color != null) return color!.withOpacity(_bgOpacity);
    return AppColors.isDark
        ? Color.fromRGBO(20, 20, 30, _bgOpacity)
        : Color.fromRGBO(255, 255, 255, _bgOpacity);
  }
  Color get _borderColor => Color.fromRGBO(255, 255, 255, _borderOp);
  List<BoxShadow> get _shadows => shadowEnabled
      ? [
          BoxShadow(
            color: AppColors.isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ]
      : [];

  @override
  Widget build(BuildContext context) {
    final reduceTransparency = MediaQuery.of(context).disableAnimations;

    if (reduceTransparency || !useBlur) {
      return Container(
        padding: padding,
        margin: margin,
        constraints: constraints,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: _borderColor, width: 1),
          boxShadow: _shadows,
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: Container(
          padding: padding,
          margin: margin,
          constraints: constraints,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: _shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}
