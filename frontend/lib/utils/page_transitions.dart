import 'package:flutter/material.dart';

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final reverseTween = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        );
}

class FadeScaleRoute extends PageRouteBuilder {
  final Widget page;
  FadeScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
        );
}

class SpotRevealRoute extends PageRouteBuilder {
  final Widget page;
  final Offset origin;
  SpotRevealRoute({required this.page, this.origin = Offset.zero})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final size = MediaQuery.of(context).size;
            final center = Offset(size.width / 2, size.height / 2);
            final beginScale = origin == Offset.zero
                ? 0.01
                : (origin - center).distance / (size.shortestSide * 0.7);
            final tween = Tween<double>(begin: beginScale.clamp(0.01, 0.5), end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            return ScaleTransition(
              scale: animation.drive(tween),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: child,
              ),
            );
          },
        );
}
