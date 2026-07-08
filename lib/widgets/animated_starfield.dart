import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 全局星空动画组件 - 对齐网页版 Starfield.tsx
/// 羽化发光 + 呼吸闪烁 + 七彩循环变色
class AnimatedStarfield extends StatefulWidget {
  final Widget? child;

  const AnimatedStarfield({super.key, this.child});

  @override
  State<AnimatedStarfield> createState() => _AnimatedStarfieldState();
}

class _AnimatedStarfieldState extends State<AnimatedStarfield>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  Size _lastSize = Size.zero;

  // 七彩极光色
  static const _auroraColors = [
    Color(0xFFFF4D6D),
    Color(0xFFFF9F1C),
    Color(0xFFFFD60A),
    Color(0xFF70E000),
    Color(0xFF00E5FF),
    Color(0xFF3A86FF),
    Color(0xFF9D4EDD),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _stars = [];
  }

  void _ensureStars(Size size) {
    if (size == _lastSize && _stars.isNotEmpty) return;
    _lastSize = size;
    _stars = [];

    // 网格打散方案：将屏幕分成 6x12 = 72 格，从每格中心随机偏移，保证均匀分布
    final rng = Random(42);
    const gridCols = 6;
    const gridRows = 12;
    final cellW = size.width / gridCols;
    final cellH = size.height / gridRows;

    // 生成所有网格候选位置并打乱
    final cells = <_GridCell>[];
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        cells.add(_GridCell(
          x: (c + 0.2 + rng.nextDouble() * 0.6) * cellW,
          y: (r + 0.2 + rng.nextDouble() * 0.6) * cellH,
        ));
      }
    }
    cells.shuffle(rng);

    // 大星 3 颗 — 带光晕，慢呼吸
    for (int i = 0; i < 3; i++) {
      final cell = cells[i];
      _stars.add(_Star(
        x: cell.x, y: cell.y,
        radius: 2.0 + rng.nextDouble() * 1.2,
        baseAlpha: 0.6 + rng.nextDouble() * 0.2,
        twinkleSpeed: 0.3 + rng.nextDouble() * 0.4,
        twinkleOffset: rng.nextDouble() * pi * 2,
        colorPhase: rng.nextDouble() * pi * 2,
        colorSpeed: 0.08 + rng.nextDouble() * 0.05,
        hasHalo: true,
      ));
    }

    // 中星 8 颗
    for (int i = 0; i < 8; i++) {
      final cell = cells[3 + i];
      _stars.add(_Star(
        x: cell.x, y: cell.y,
        radius: 1.0 + rng.nextDouble() * 0.6,
        baseAlpha: 0.35 + rng.nextDouble() * 0.25,
        twinkleSpeed: 0.5 + rng.nextDouble() * 0.6,
        twinkleOffset: rng.nextDouble() * pi * 2,
        colorPhase: rng.nextDouble() * pi * 2,
        colorSpeed: 0.05 + rng.nextDouble() * 0.04,
        hasHalo: false,
      ));
    }

    // 小星 22 颗
    for (int i = 0; i < 22; i++) {
      final cell = cells[11 + i];
      _stars.add(_Star(
        x: cell.x, y: cell.y,
        radius: 0.3 + rng.nextDouble() * 0.4,
        baseAlpha: 0.15 + rng.nextDouble() * 0.2,
        twinkleSpeed: 0.8 + rng.nextDouble() * 1.0,
        twinkleOffset: rng.nextDouble() * pi * 2,
        colorPhase: rng.nextDouble() * pi * 2,
        colorSpeed: 0.03 + rng.nextDouble() * 0.03,
        hasHalo: false,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _ensureStars(size);

    return Stack(
      children: [
        Container(color: AppColors.background),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _StarfieldPainter(
                stars: _stars,
                time: _controller.value * 60, // 转为秒
              ),
              size: Size.infinite,
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _Star {
  final double x, y, radius, baseAlpha, twinkleSpeed, twinkleOffset;
  final double colorPhase, colorSpeed;
  final bool hasHalo;

  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseAlpha,
    required this.twinkleSpeed,
    required this.twinkleOffset,
    required this.colorPhase,
    required this.colorSpeed,
    required this.hasHalo,
  });
}

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double time;

  _StarfieldPainter({required this.stars, required this.time});

  /// 在七彩颜色之间平滑插值
  Color _cycleColor(double phase, double speed) {
    const colors = _AnimatedStarfieldState._auroraColors;
    final len = colors.length;
    final t = (time * speed + phase) % (pi * 2);
    final normalized = (t / (pi * 2)) * len;
    final idx = normalized.floor() % len;
    final nextIdx = (idx + 1) % len;
    final frac = normalized - normalized.floor();
    return Color.lerp(colors[idx], colors[nextIdx], frac)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      // 呼吸闪烁
      double alpha = star.baseAlpha +
          sin(time * star.twinkleSpeed + star.twinkleOffset) * 0.25;
      alpha = alpha.clamp(0.05, 1.0);

      // 七彩循环变色
      final color = _cycleColor(star.colorPhase, star.colorSpeed);
      final center = Offset(star.x, star.y);

      // 光晕（大星）— 径向渐变羽化
      if (star.hasHalo) {
        final haloRadius = star.radius * 6.0;
        final haloRect = Rect.fromCircle(center: center, radius: haloRadius);
        final haloGradient = RadialGradient(
          colors: [
            color.withOpacity(alpha * 0.2),
            color.withOpacity(alpha * 0.06),
            color.withOpacity(0),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(haloRect);
        canvas.drawRect(haloRect, Paint()..shader = haloGradient);
      }

      // 星星核心 — 径向渐变羽化发光
      final coreRadius = star.radius * 1.8; // 稍大于实际半径用于羽化边缘
      final coreRect = Rect.fromCircle(center: center, radius: coreRadius);
      final coreGradient = RadialGradient(
        colors: [
          color.withOpacity(alpha),
          color.withOpacity(alpha * 0.4),
          color.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(coreRect);
      canvas.drawRect(coreRect, Paint()..shader = coreGradient);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => true;
}


class _GridCell {
  final double x, y;
  _GridCell({required this.x, required this.y});
}
