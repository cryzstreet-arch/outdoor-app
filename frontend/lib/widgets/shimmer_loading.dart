import 'package:flutter/material.dart';
import '../config/constants.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? AppColors.superficie;
    final highlight = widget.highlightColor ?? AppColors.fondo;
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    if (!isCurrent) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 150, borderRadius: 16),
          const SizedBox(height: 8),
          ShimmerBox(width: 120, height: 16),
          const SizedBox(height: 8),
          ShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          ShimmerBox(width: 200, height: 14),
        ],
      ),
    );
  }
}

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ShimmerBox(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 12),
          ShimmerBox(width: 140, height: 20),
          const SizedBox(height: 8),
          ShimmerBox(width: 180, height: 14),
          const SizedBox(height: 24),
          ShimmerBox(width: double.infinity, height: 160, borderRadius: 16),
          const SizedBox(height: 24),
          ShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
        ],
      ),
    );
  }
}

class ShimmerDetail extends StatelessWidget {
  const ShimmerDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 200, borderRadius: 12),
          const SizedBox(height: 16),
          ShimmerBox(width: 180, height: 22),
          const SizedBox(height: 8),
          ShimmerBox(width: 120, height: 14),
          const SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          ShimmerBox(width: 250, height: 14),
          const SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 100, borderRadius: 12),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ShimmerBox(width: 60, height: 50),
              ShimmerBox(width: 60, height: 50),
              ShimmerBox(width: 60, height: 50),
            ],
          ),
          const SizedBox(height: 20),
          ShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
          const SizedBox(height: 12),
          ShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
        ],
      ),
    );
  }
}
