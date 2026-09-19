import 'package:flutter/material.dart';

/// A lightweight, 60fps hardware-accelerated Shimmer effect for skeleton loading screens.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
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
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (slidePercent * 2.4 - 1.2);
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

/// A single placeholder bar or box with rounded corners.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 6,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white, // ShaderMask BlendMode.srcIn paints over this shape
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A clean, realistic A4 document skeleton simulating an in-progress PDF view
/// (similar to Instagram/Facebook content skeletons, without any download progress bar).
class PdfDocumentSkeleton extends StatelessWidget {
  final String title;
  final String subtitle;
  final double? progress;
  final VoidCallback? onCancel;

  const PdfDocumentSkeleton({
    super.key,
    required this.title,
    required this.subtitle,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D30) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ShimmerLoading(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header tags skeleton
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 90, height: 16, borderRadius: 8),
                    SkeletonBox(width: 40, height: 16, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 18),

                // Main Document Title Lines
                const SkeletonBox(width: double.infinity, height: 20, borderRadius: 6),
                const SizedBox(height: 8),
                const SkeletonBox(width: 240, height: 20, borderRadius: 6),
                const SizedBox(height: 16),

                // Section 1 Header
                const SkeletonBox(width: 140, height: 16, borderRadius: 5),
                const SizedBox(height: 12),

                // Paragraph lines
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: 290, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: 180, height: 12, borderRadius: 4),
                const SizedBox(height: 22),

                // Simulated diagram / illustration / math formula box
                const SkeletonBox(width: double.infinity, height: 135, borderRadius: 12),
                const SizedBox(height: 22),

                // Section 2 Header
                const SkeletonBox(width: 160, height: 16, borderRadius: 5),
                const SizedBox(height: 12),

                // Paragraph lines
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: 240, height: 12, borderRadius: 4),
                const SizedBox(height: 22),

                // Section 3 Header
                const SkeletonBox(width: 120, height: 16, borderRadius: 5),
                const SizedBox(height: 12),
                const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                const SkeletonBox(width: 260, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
