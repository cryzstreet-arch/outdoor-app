import 'package:flutter/material.dart';
import '../config/constants.dart';

class SkeuomorphicButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final IconData? icon;

  const SkeuomorphicButton({
    required this.text,
    this.onPressed,
    this.loading = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            offset: const Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: color ?? AppColors.primario,
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (color ?? AppColors.primario).withOpacity(0.5),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? AppColors.primario).withOpacity(0.8),
                  color ?? AppColors.primario,
                  (color ?? AppColors.primario).withOpacity(0.9),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
