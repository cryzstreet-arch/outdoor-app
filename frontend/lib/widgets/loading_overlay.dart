import 'package:flutter/material.dart';
import '../config/constants.dart';

class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;

  const LoadingOverlay({required this.loading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.fondo,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20, offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.primario,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
