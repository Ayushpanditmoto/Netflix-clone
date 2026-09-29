import 'package:flutter/material.dart';

/// Sweeps a light band across [child] to signal that content is loading.
///
/// Built in-house with a [ShaderMask] so the project keeps its dependency list
/// unchanged. When the platform asks for reduced motion the band is frozen in
/// place instead of animating.
class Shimmer extends StatefulWidget {
  const Shimmer({
    required this.child,
    this.baseColor = const Color(0xFF1A1A1A),
    this.highlightColor = const Color(0xFF2E2E2E),
    this.period = const Duration(milliseconds: 1400),
    super.key,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  /// Where the highlight band sits inside the gradient. The sweep distance is
  /// derived from these so the band enters and leaves exactly at the edges,
  /// with no visible pause when the animation loops.
  static const _stops = <double>[0.35, 0.5, 0.65];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sweep = 1 - _stops.first;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: _stops,
              transform: _SlidingGradient(sweep * (_controller.value * 2 - 1)),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Translates the highlight band across the shader bounds.
class _SlidingGradient extends GradientTransform {
  const _SlidingGradient(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// A plain placeholder block. Its colour is replaced by the surrounding
/// [Shimmer] gradient, so the fill here only has to stay opaque.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({this.width, this.height, this.borderRadius = 8, super.key});

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Poster-shaped skeleton matching the footprint of `MovieTile`, for grids that
/// mix already-loaded titles with ones still on the way.
class PosterPlaceholder extends StatelessWidget {
  const PosterPlaceholder({this.showTitle = false, super.key});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(child: ShimmerBox()),
          if (showTitle) ...[
            const SizedBox(height: 8),
            const ShimmerBox(height: 12),
            const SizedBox(height: 6),
            const FractionallySizedBox(
              widthFactor: 0.6,
              child: ShimmerBox(height: 12),
            ),
          ],
        ],
      ),
    );
  }
}
