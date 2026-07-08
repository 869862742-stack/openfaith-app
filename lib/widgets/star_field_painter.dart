import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 星空背景 Widget
/// 对齐网页版 Starfield.tsx：羽化发光 + 呼吸闪烁 + 七彩循环变色
class StarFieldBackground extends StatefulWidget {
  final Widget? child;
  const StarFieldBackground({super.key, this.child});

  @override
  State<StarFieldBackground> createState() => _StarFieldBackgroundState();
}

class _StarFieldBackgroundState extends State<StarFieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<_Star>? _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Star> _generateStars(Size size) {
    final rng = Random(42);
    final stars = <_Star>[];

    // 大星 2 颗（有光晕）
    for (int i = 0; i < 2; i++) {
      stars.add(_Star(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 2.5 + rng.nextDouble() * 1.5,
        baseAlpha: 0.85 + rng.nextDouble() * 0.15,
        twinkleSpeed: 0.3 + rng.nextDouble() * 0.8,
        twinkleOffset: rng.nextDouble() * pi * 2,
        colorCycleSpeed: 0.05 + rng.nextDouble() * 0.1,
        colorCycleOffset: rng.nextDouble() * pi * 2,
        hasHalo: true,
      ));
    }

    // 中星 5 颗
    for (int i = 0; i < 5; i++) {
      stars.add(_Star(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 1.2 + rng.nextDouble() * 1.2,
        baseAlpha: 0.6 + rng.nextDouble() * 0.3,
        twinkleSpeed: 0.5 + rng.nextDouble() * 1.0,
        twinkleOffset: rng.nextDouble() * pi * 2,
        colorCycleSpeed: 0.03 + rng.nextDouble() * 0.08,
        colorCycleOffset: rng.nextDouble() * pi * 2,
        hasHalo: false,
      ));
    }

    // 小星 20 颗
    for (int i = 0; i < 20; i++) {
      stars.add(_Star(
        x: rng.nextDouble() * size.width,
        y: rng.nextDouble() * size.height,
        size: 0.6 + rng.nextDouble() * 0.8,
        baseAlpha: 0.3 + rng.nextDouble() * 0.3,
        twinkleSpeed: 0.8 + rng.nextDouble() * 1.5,
        twinkleOffset: rng.nextDouble() * pi * 2,
        colorCycleSpeed: 0.02 + rng.nextDouble() * 0.06,
        colorCycleOffset: rng.nextDouble() * pi * 2,
        hasHalo: false,
      ));
    }

    return stars;
  }

  /// 在七彩颜色之间平滑插值
  Color _cycleColor(_Star star, double time) {
    final colors = AppColors.auroraColors;
    final len = colors.length;
    final t = (time * star.colorCycleSpeed + star.colorCycleOffset) % (pi * 2);
    final normalized = (t / (pi * 2)) * len;
    final idx = normalized.floor() % len;
    final nextIdx = (idx + 1) % len;
    final frac = normalized - normalized.floor();
    return Color.lerp(colors[idx], colors[nextIdx], frac)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            _stars ??= _generateStars(constraints.biggest);
            return CustomPaint(
              size: constraints.biggest,
              painter: _StarFieldPainter(
                _stars!,
                _controller.value * 600,
                _cycleColor,
              ),
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double time;
  final Color Function(_Star, double) cycleColor;

  _StarFieldPainter(this.stars, this.time, this.cycleColor);

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // 呼吸闪烁
      double alpha = star.baseAlpha +
          sin(time * star.twinkleSpeed + star.twinkleOffset) * 0.3;
      alpha = alpha.clamp(0.08, 1.0);

      // 七彩循环变色
      final currentColor = cycleColor(star, time);

      // 光晕（大星才有）— 径向渐变羽化
      if (star.hasHalo) {
        final haloRadius = star.size * 5.0;
        final haloRect = Rect.fromCircle(
          center: Offset(star.x, star.y),
          radius: haloRadius,
        );
        final haloShader = RadialGradient(
          colors: [
            currentColor.withOpacity(alpha * 0.3),
            currentColor.withOpacity(alpha * 0.08),
            currentColor.withOpacity(0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(haloRect);
        canvas.drawRect(haloRect, Paint()..shader = haloShader);
      }

      // 星星核心 — 径向渐变羽化发光
      final coreRadius = star.size;
      final coreRect = Rect.fromCircle(
        center: Offset(star.x, star.y),
        radius: coreRadius,
      );
      final coreShader = RadialGradient(
        colors: [
          currentColor.withOpacity(alpha),
          currentColor.withOpacity(alpha * 0.5),
          currentColor.withOpacity(0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(coreRect);
      canvas.drawRect(coreRect, Paint()..shader = coreShader);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) => true;
}

class _Star {
  final double x, y, size;
  final double baseAlpha;
  final double twinkleSpeed;
  final double twinkleOffset;
  final double colorCycleSpeed;
  final double colorCycleOffset;
  final bool hasHalo;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseAlpha,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.colorCycleSpeed,
    required this.colorCycleOffset,
    required this.hasHalo,
  });
}
