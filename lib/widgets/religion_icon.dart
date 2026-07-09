import 'dart:math';
import 'package:flutter/material.dart';

/// 宗教图标组件 - 对齐网页版 ReligionIcon.tsx
class ReligionIconWidget extends StatelessWidget {
  final String name;
  final double size;

  const ReligionIconWidget({super.key, required this.name, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final config = getReligionIconConfig(name);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ReligionIconPainter(shape: config.$1, color: config.$2),
      ),
    );
  }
}

/// 获取宗教图标配置 (shape, color) - 严格匹配网页版 ReligionIcon.tsx 映射
(String, Color) getReligionIconConfig(String name) {
  const map = <String, (String, Color)>{
    '基督教': ('cross', Color(0xFFFFD60A)),
    '天主教': ('papal_cross', Color(0xFFFFD60A)),
    '东正教': ('orthodox_cross', Color(0xFFFFD60A)),
    '伊斯兰教': ('crescent', Color(0xFF00E5FF)),
    '犹太教': ('star_of_david', Color(0xFF3A86FF)),
    '佛教': ('lotus', Color(0xFFFF9F1C)),
    '印度教': ('om', Color(0xFFFF4D6D)),
    '道教': ('yin_yang', Color(0xFF70E000)),
    '锡克教': ('khanda', Color(0xFF9D4EDD)),
    '巴哈伊教': ('star9', Color(0xFFFFD60A)),
    '摩门教': ('angel', Color(0xFFFFD60A)),
    '耶和华见证人': ('tower', Color(0xFF3A86FF)),
    '琐罗亚斯德教': ('faravahar', Color(0xFFFF9F1C)),
    '诺斯替': ('snake', Color(0xFF9D4EDD)),
    '卡巴拉': ('tree', Color(0xFF70E000)),
    '神道教': ('torii', Color(0xFFFF4D6D)),
    '耆那教': ('jain_hand', Color(0xFFFF9F1C)),
    '德鲁兹教': ('star5', Color(0xFF00E5FF)),
    '约鲁巴教': ('circle', Color(0xFFFF4D6D)),
    '伏都教': ('eye', Color(0xFF9D4EDD)),
    '雅兹迪': ('sun', Color(0xFFFFD60A)),
    '曼达安': ('wave', Color(0xFF00E5FF)),
    '玛雅/阿兹特克': ('pyramid', Color(0xFF70E000)),
    '毛利宗教': ('spiral', Color(0xFFFF4D6D)),
    '天理教': ('crown', Color(0xFFFF9F1C)),
    '天道教': ('taeguk', Color(0xFF3A86FF)),
    '高台教': ('divine_eye', Color(0xFFFFD60A)),
    '宗教研究者': ('book', Color(0xFF00E5FF)),
    '经文爱好者': ('scroll', Color(0xFF70E000)),
    '寻求者': ('compass', Color(0xFF9D4EDD)),
  };
  if (map.containsKey(name)) return map[name]!;
  final base = name.replaceAll(RegExp(r'[（(][^)）]+[)）]'), '').trim();
  if (base != name && map.containsKey(base)) return map[base]!;
  for (final e in map.entries) {
    if (name.contains(e.key) || e.key.contains(name)) return e.value;
  }
  return ('default', const Color(0x80FFFFFF));
}

/// 宗教圆形图标（百科卡片中使用）
class ReligionCircleIcon extends StatelessWidget {
  final String name;
  final double size;
  const ReligionCircleIcon({super.key, required this.name, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final (_, color) = getReligionIconConfig(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Center(child: ReligionIconWidget(name: name, size: size * 0.6)),
    );
  }
}

class _ReligionIconPainter extends CustomPainter {
  final String shape;
  final Color color;
  _ReligionIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    switch (shape) {
      case 'cross':
        final bw = w * 0.22;
        fill.style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: bw, height: h * 0.85),
            Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - h * 0.08), width: w * 0.65, height: bw),
            Radius.circular(1)), fill);
      case 'papal_cross':
        final bw = w * 0.15;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: bw, height: h * 0.88),
            Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - h * 0.22), width: w * 0.58, height: bw),
            Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - h * 0.04), width: w * 0.42, height: bw * 0.85),
            Radius.circular(1)), Paint()..color = color.withOpacity(0.8));
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy + h * 0.12), width: w * 0.3, height: bw * 0.7),
            Radius.circular(1)), Paint()..color = color.withOpacity(0.6));
      case 'orthodox_cross':
        final bw = w * 0.17;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: bw, height: h * 0.88),
            Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy - h * 0.18), width: w * 0.55, height: bw),
            Radius.circular(1)), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy + h * 0.02), width: w * 0.4, height: bw * 0.85),
            Radius.circular(1)), fill);
      case 'crescent':
        final r = w * 0.38;
        final outer = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        final inner = Path()..addOval(Rect.fromCircle(center: Offset(cx + r * 0.3, cy - r * 0.05), radius: r * 0.78));
        final diff = Path.combine(PathOperation.difference, outer, inner);
        canvas.drawPath(diff, fill);
        canvas.drawCircle(Offset(cx + r * 0.5, cy - r * 0.5), w * 0.05, fill);
      case 'star_of_david':
        final r = w * 0.38;
        final up = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx - r * 0.87, cy + r * 0.5)
          ..lineTo(cx + r * 0.87, cy + r * 0.5)
          ..close();
        final dn = Path()
          ..moveTo(cx, cy + r)
          ..lineTo(cx - r * 0.87, cy - r * 0.5)
          ..lineTo(cx + r * 0.87, cy - r * 0.5)
          ..close();
        canvas.drawPath(up, fill);
        canvas.drawPath(dn, fill);
      case 'lotus':
        final pw = w * 0.18, ph = h * 0.35;
        final c1 = Path()
          ..moveTo(cx, cy - ph)
          ..quadraticBezierTo(cx + pw, cy - ph * 0.3, cx, cy + ph * 0.3)
          ..quadraticBezierTo(cx - pw, cy - ph * 0.3, cx, cy - ph);
        canvas.drawPath(c1, fill);
        canvas.drawPath(
            Path()
              ..moveTo(cx - w * 0.05, cy - ph * 0.6)
              ..quadraticBezierTo(cx - w * 0.35, cy - ph * 0.2, cx - w * 0.1, cy + ph * 0.3)
              ..quadraticBezierTo(cx - w * 0.15, cy - ph * 0.1, cx - w * 0.05, cy - ph * 0.6),
            Paint()..color = color.withOpacity(0.7));
        canvas.drawPath(
            Path()
              ..moveTo(cx + w * 0.05, cy - ph * 0.6)
              ..quadraticBezierTo(cx + w * 0.35, cy - ph * 0.2, cx + w * 0.1, cy + ph * 0.3)
              ..quadraticBezierTo(cx + w * 0.15, cy - ph * 0.1, cx + w * 0.05, cy - ph * 0.6),
            Paint()..color = color.withOpacity(0.7));
      case 'yin_yang':
        final r = w * 0.38;
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            -pi / 2, pi, true, Paint()..color = Colors.white.withOpacity(0.85));
        canvas.drawCircle(Offset(cx, cy - r * 0.48), r * 0.13, Paint()..color = Colors.white.withOpacity(0.85));
        canvas.drawCircle(Offset(cx, cy + r * 0.48), r * 0.13, fill);
      case 'star9':
      case 'star5':
        final n = shape == 'star9' ? 9 : 5;
        final r = w * 0.38;
        final p = Path();
        for (int i = 0; i < n * 2; i++) {
          final a = (i * pi / n) - pi / 2;
          final rr = i.isEven ? r : r * 0.45;
          final px = cx + rr * cos(a);
          final py = cy + rr * sin(a);
          i == 0 ? p.moveTo(px, py) : p.lineTo(px, py);
        }
        p.close();
        canvas.drawPath(p, fill);
      case 'torii':
        final sw = w * 0.09;
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.28, cy - h * 0.05, sw, h * 0.45), fill);
        canvas.drawRect(Rect.fromLTWH(cx + w * 0.28 - sw, cy - h * 0.05, sw, h * 0.45), fill);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.38, cy - h * 0.1, w * 0.76, sw * 0.9), fill);
        final tp = Path()
          ..moveTo(cx - w * 0.42, cy - h * 0.25)
          ..quadraticBezierTo(cx, cy - h * 0.42, cx + w * 0.42, cy - h * 0.25)
          ..lineTo(cx + w * 0.42, cy - h * 0.19)
          ..quadraticBezierTo(cx, cy - h * 0.36, cx - w * 0.42, cy - h * 0.19)
          ..close();
        canvas.drawPath(tp, fill);
      case 'faravahar':
        // 琐罗亚斯德教 - Faravahar: winged disc with human figure
        // Central disc (ring)
        final ringR = w * 0.18;
        canvas.drawCircle(Offset(cx, cy), ringR, fill);
        canvas.drawCircle(Offset(cx, cy), ringR * 0.6, Paint()..color = const Color(0xFF050816));

        // Human figure on top (simplified - head and body)
        canvas.drawCircle(Offset(cx, cy - ringR * 1.6), w * 0.06, fill);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - ringR * 1.1), width: w * 0.06, height: h * 0.12), fill);

        // Wings (3-layer feathers on each side, matching Faravahar symbolism)
        final wingY = cy - h * 0.05;
        for (int side = -1; side <= 1; side += 2) {
          for (int layer = 0; layer < 3; layer++) {
            final layerOffset = layer * h * 0.06;
            final wingPath = Path()
              ..moveTo(cx + side * ringR * 0.8, wingY + layerOffset)
              ..quadraticBezierTo(
                cx + side * w * 0.45, wingY - h * 0.15 + layerOffset,
                cx + side * w * 0.4, wingY - h * 0.08 + layerOffset,
              )
              ..lineTo(cx + side * ringR * 0.6, wingY + layerOffset)
              ..close();
            canvas.drawPath(wingPath, Paint()..color = color.withOpacity(0.9 - layer * 0.2));
          }
        }

        // Tail feathers (3 downward)
        for (int i = -1; i <= 1; i++) {
          final tailPath = Path()
            ..moveTo(cx + i * w * 0.06, cy + ringR * 0.6)
            ..quadraticBezierTo(
              cx + i * w * 0.12, cy + h * 0.35,
              cx + i * w * 0.08, cy + h * 0.38,
            )
            ..lineTo(cx + i * w * 0.04, cy + ringR * 0.6)
            ..close();
          canvas.drawPath(tailPath, Paint()..color = color.withOpacity(0.7));
        }

        // Streamers (two curling lines from the ring)
        final streamerPaint = Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.03
          ..strokeCap = StrokeCap.round;
        for (int side = -1; side <= 1; side += 2) {
          canvas.drawPath(
            Path()
              ..moveTo(cx + side * ringR * 0.3, cy + ringR * 0.6)
              ..quadraticBezierTo(
                cx + side * w * 0.15, cy + h * 0.32,
                cx + side * w * 0.2, cy + h * 0.35,
              ),
            streamerPaint,
          );
        }
      case 'pyramid':
        final pp = Path()
          ..moveTo(cx, cy - h * 0.35)
          ..lineTo(cx + w * 0.38, cy + h * 0.35)
          ..lineTo(cx - w * 0.38, cy + h * 0.35)
          ..close();
        canvas.drawPath(pp, fill);
      case 'crown':
        final cp = Path()
          ..moveTo(cx - w * 0.35, cy + h * 0.2)
          ..lineTo(cx - w * 0.35, cy - h * 0.05)
          ..lineTo(cx - w * 0.18, cy + h * 0.08)
          ..lineTo(cx, cy - h * 0.25)
          ..lineTo(cx + w * 0.18, cy + h * 0.08)
          ..lineTo(cx + w * 0.35, cy - h * 0.05)
          ..lineTo(cx + w * 0.35, cy + h * 0.2)
          ..close();
        canvas.drawPath(cp, fill);
      case 'sun':
        canvas.drawCircle(Offset(cx, cy), w * 0.2, fill);
        for (int i = 0; i < 8; i++) {
          final a = i * pi / 4;
          canvas.drawLine(
              Offset(cx + w * 0.25 * cos(a), cy + w * 0.25 * sin(a)),
              Offset(cx + w * 0.38 * cos(a), cy + w * 0.38 * sin(a)),
              Paint()..color = color..strokeWidth = w * 0.06..strokeCap = StrokeCap.round);
        }
      case 'eye':
        final ep = Path()
          ..moveTo(cx - w * 0.38, cy)
          ..quadraticBezierTo(cx, cy - h * 0.28, cx + w * 0.38, cy)
          ..quadraticBezierTo(cx, cy + h * 0.28, cx - w * 0.38, cy);
        canvas.drawPath(ep, fill);
        canvas.drawCircle(Offset(cx, cy), w * 0.1, Paint()..color = const Color(0xFF050816));
      case 'compass':
        canvas.drawCircle(Offset(cx, cy), w * 0.34, fill);
        final np = Path()
          ..moveTo(cx, cy - w * 0.24)
          ..lineTo(cx + w * 0.06, cy)
          ..lineTo(cx, cy + w * 0.24)
          ..lineTo(cx - w * 0.06, cy)
          ..close();
        canvas.drawPath(np, Paint()..color = const Color(0xFF050816));
      case 'spiral':
        final sp = Path();
        for (int i = 0; i <= 50; i++) {
          final t = i / 50 * 2.5 * pi;
          final r = w * 0.04 * (i / 50) * 6;
          final x = cx + r * cos(t);
          final y = cy + r * sin(t);
          i == 0 ? sp.moveTo(x, y) : sp.lineTo(x, y);
        }
        canvas.drawPath(sp, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = w * 0.06..strokeCap = StrokeCap.round);
      case 'wave':
        final wp = Path()
          ..moveTo(cx - w * 0.38, cy)
          ..quadraticBezierTo(cx - w * 0.19, cy - h * 0.18, cx, cy)
          ..quadraticBezierTo(cx + w * 0.19, cy + h * 0.18, cx + w * 0.38, cy);
        canvas.drawPath(wp, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = w * 0.07..strokeCap = StrokeCap.round);
      case 'khanda':
        canvas.drawLine(Offset(cx, cy - h * 0.38), Offset(cx, cy + h * 0.38), stroke);
        canvas.drawCircle(Offset(cx, cy), w * 0.18, fill);
      case 'jain_hand':
        // 耆那教 - Jain Hand: open palm with wheel (Ahimsa symbol)
        // Palm
        final palmPath = Path()
          ..moveTo(cx - w * 0.22, cy + h * 0.32)
          ..lineTo(cx - w * 0.22, cy - h * 0.02)
          ..quadraticBezierTo(cx - w * 0.22, cy - h * 0.15, cx - w * 0.15, cy - h * 0.25)
          ..quadraticBezierTo(cx - w * 0.08, cy - h * 0.35, cx - w * 0.04, cy - h * 0.2)
          ..lineTo(cx - w * 0.04, cy - h * 0.05)
          ..lineTo(cx, cy - h * 0.05)
          ..lineTo(cx, cy - h * 0.35)
          ..quadraticBezierTo(cx, cy - h * 0.42, cx + w * 0.04, cy - h * 0.42)
          ..quadraticBezierTo(cx + w * 0.08, cy - h * 0.42, cx + w * 0.08, cy - h * 0.35)
          ..lineTo(cx + w * 0.08, cy - h * 0.05)
          ..lineTo(cx + w * 0.12, cy - h * 0.05)
          ..lineTo(cx + w * 0.12, cy - h * 0.3)
          ..quadraticBezierTo(cx + w * 0.12, cy - h * 0.37, cx + w * 0.16, cy - h * 0.37)
          ..quadraticBezierTo(cx + w * 0.2, cy - h * 0.37, cx + w * 0.2, cy - h * 0.3)
          ..lineTo(cx + w * 0.2, cy - h * 0.02)
          ..lineTo(cx + w * 0.24, cy - h * 0.02)
          ..lineTo(cx + w * 0.24, cy - h * 0.2)
          ..quadraticBezierTo(cx + w * 0.24, cy - h * 0.26, cx + w * 0.28, cy - h * 0.26)
          ..quadraticBezierTo(cx + w * 0.32, cy - h * 0.26, cx + w * 0.32, cy - h * 0.2)
          ..lineTo(cx + w * 0.32, cy + h * 0.05)
          ..quadraticBezierTo(cx + w * 0.32, cy + h * 0.32, cx, cy + h * 0.38)
          ..quadraticBezierTo(cx - w * 0.32, cy + h * 0.32, cx - w * 0.22, cy + h * 0.32)
          ..close();
        canvas.drawPath(palmPath, fill);
        // Wheel (Dharmachakra) in the palm center
        final wheelR = w * 0.08;
        final wheelCx = cx + w * 0.04;
        final wheelCy = cy + h * 0.08;
        canvas.drawCircle(Offset(wheelCx, wheelCy), wheelR, Paint()..color = const Color(0xFF050816));
        canvas.drawCircle(Offset(wheelCx, wheelCy), wheelR * 0.5, fill);
        // Wheel spokes
        final spokePaint = Paint()
          ..color = color
          ..strokeWidth = w * 0.015
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 4; i++) {
          final a = i * pi / 2;
          canvas.drawLine(
            Offset(wheelCx + wheelR * 0.5 * cos(a), wheelCy + wheelR * 0.5 * sin(a)),
            Offset(wheelCx + wheelR * cos(a), wheelCy + wheelR * sin(a)),
            spokePaint,
          );
        }
      case 'snake':
        // 诺斯替 - Gnostic snake (ouroboros-like)
        final snakePath = Path()
          ..moveTo(cx - w * 0.3, cy)
          ..quadraticBezierTo(cx - w * 0.3, cy - h * 0.3, cx, cy - h * 0.25)
          ..quadraticBezierTo(cx + w * 0.3, cy - h * 0.2, cx + w * 0.3, cy)
          ..quadraticBezierTo(cx + w * 0.3, cy + h * 0.2, cx + w * 0.1, cy + h * 0.25)
          ..quadraticBezierTo(cx - w * 0.05, cy + h * 0.28, cx - w * 0.15, cy + h * 0.15);
        canvas.drawPath(snakePath, Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07
          ..strokeCap = StrokeCap.round);
        // Head
        canvas.drawCircle(Offset(cx - w * 0.15, cy + h * 0.15), w * 0.05, fill);
      case 'tree':
        // 卡巴拉 - Kabbalistic Tree of Life (simplified)
        // Three columns of sephirot
        final dotR = w * 0.055;
        // Left column
        canvas.drawCircle(Offset(cx - w * 0.22, cy - h * 0.28), dotR, fill);
        canvas.drawCircle(Offset(cx - w * 0.22, cy - h * 0.05), dotR, fill);
        canvas.drawCircle(Offset(cx - w * 0.18, cy + h * 0.18), dotR, fill);
        // Middle column
        canvas.drawCircle(Offset(cx, cy - h * 0.35), dotR, fill);
        canvas.drawCircle(Offset(cx, cy - h * 0.15), dotR, fill);
        canvas.drawCircle(Offset(cx, cy + h * 0.05), dotR, fill);
        canvas.drawCircle(Offset(cx, cy + h * 0.25), dotR, fill);
        // Right column
        canvas.drawCircle(Offset(cx + w * 0.22, cy - h * 0.28), dotR, fill);
        canvas.drawCircle(Offset(cx + w * 0.22, cy - h * 0.05), dotR, fill);
        canvas.drawCircle(Offset(cx + w * 0.18, cy + h * 0.18), dotR, fill);
        // Connecting lines
        final linePaint = Paint()
          ..color = color.withOpacity(0.4)
          ..strokeWidth = w * 0.02
          ..strokeCap = StrokeCap.round;
        // Simplified connections
        canvas.drawLine(Offset(cx, cy - h * 0.35), Offset(cx - w * 0.22, cy - h * 0.28), linePaint);
        canvas.drawLine(Offset(cx, cy - h * 0.35), Offset(cx + w * 0.22, cy - h * 0.28), linePaint);
        canvas.drawLine(Offset(cx - w * 0.22, cy - h * 0.28), Offset(cx - w * 0.22, cy - h * 0.05), linePaint);
        canvas.drawLine(Offset(cx + w * 0.22, cy - h * 0.28), Offset(cx + w * 0.22, cy - h * 0.05), linePaint);
        canvas.drawLine(Offset(cx, cy - h * 0.15), Offset(cx - w * 0.22, cy - h * 0.05), linePaint);
        canvas.drawLine(Offset(cx, cy - h * 0.15), Offset(cx + w * 0.22, cy - h * 0.05), linePaint);
        canvas.drawLine(Offset(cx, cy - h * 0.15), Offset(cx, cy + h * 0.05), linePaint);
        canvas.drawLine(Offset(cx - w * 0.22, cy - h * 0.05), Offset(cx - w * 0.18, cy + h * 0.18), linePaint);
        canvas.drawLine(Offset(cx + w * 0.22, cy - h * 0.05), Offset(cx + w * 0.18, cy + h * 0.18), linePaint);
        canvas.drawLine(Offset(cx, cy + h * 0.05), Offset(cx - w * 0.18, cy + h * 0.18), linePaint);
        canvas.drawLine(Offset(cx, cy + h * 0.05), Offset(cx + w * 0.18, cy + h * 0.18), linePaint);
        canvas.drawLine(Offset(cx, cy + h * 0.05), Offset(cx, cy + h * 0.25), linePaint);
      case 'circle':
        canvas.drawCircle(Offset(cx, cy), w * 0.3, fill);
        canvas.drawCircle(Offset(cx, cy), w * 0.15, Paint()..color = const Color(0xFF050816));
      case 'book':
        // 宗教研究者 - open book
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - h * 0.15)
            ..lineTo(cx - w * 0.35, cy - h * 0.2)
            ..lineTo(cx - w * 0.35, cy + h * 0.25)
            ..lineTo(cx, cy + h * 0.2)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx, cy - h * 0.15)
            ..lineTo(cx + w * 0.35, cy - h * 0.2)
            ..lineTo(cx + w * 0.35, cy + h * 0.25)
            ..lineTo(cx, cy + h * 0.2)
            ..close(),
          Paint()..color = color.withOpacity(0.75),
        );
      case 'scroll':
        // 经文爱好者 - scroll
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.5, height: h * 0.55), fill);
        canvas.drawCircle(Offset(cx - w * 0.25, cy - h * 0.1), w * 0.06, fill);
        canvas.drawCircle(Offset(cx - w * 0.25, cy + h * 0.1), w * 0.06, fill);
        canvas.drawCircle(Offset(cx + w * 0.25, cy - h * 0.1), w * 0.06, Paint()..color = color.withOpacity(0.75));
        canvas.drawCircle(Offset(cx + w * 0.25, cy + h * 0.1), w * 0.06, Paint()..color = color.withOpacity(0.75));
      case 'angel':
        // 摩门教 - Angel Moroni (simplified trumpet figure)
        canvas.drawCircle(Offset(cx, cy - h * 0.2), w * 0.08, fill);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - h * 0.05), width: w * 0.08, height: h * 0.2), fill);
        // Wings
        canvas.drawPath(
          Path()
            ..moveTo(cx - w * 0.06, cy - h * 0.12)
            ..quadraticBezierTo(cx - w * 0.35, cy - h * 0.25, cx - w * 0.3, cy - h * 0.05)
            ..lineTo(cx - w * 0.06, cy - h * 0.02)
            ..close(),
          Paint()..color = color.withOpacity(0.7),
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx + w * 0.06, cy - h * 0.12)
            ..quadraticBezierTo(cx + w * 0.35, cy - h * 0.25, cx + w * 0.3, cy - h * 0.05)
            ..lineTo(cx + w * 0.06, cy - h * 0.02)
            ..close(),
          Paint()..color = color.withOpacity(0.7),
        );
        // Trumpet
        canvas.drawLine(Offset(cx + w * 0.05, cy), Offset(cx + w * 0.3, cy - h * 0.1),
            Paint()..color = color..strokeWidth = w * 0.04..strokeCap = StrokeCap.round);
        canvas.drawCircle(Offset(cx + w * 0.3, cy - h * 0.1), w * 0.05, fill);
      case 'tower':
        // 耶和华见证人 - Watchtower
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.35, height: h * 0.6), fill);
        canvas.drawPath(
          Path()
            ..moveTo(cx - w * 0.22, cy - h * 0.3)
            ..lineTo(cx, cy - h * 0.42)
            ..lineTo(cx + w * 0.22, cy - h * 0.3)
            ..close(),
          fill,
        );
        // Window
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - h * 0.08), width: w * 0.12, height: h * 0.12),
            Paint()..color = const Color(0xFF050816));
      case 'taeguk':
        // 天道教 - Taegeuk (Korean yin-yang variant)
        final r = w * 0.38;
        canvas.drawCircle(Offset(cx, cy), r, fill);
        canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
            pi / 2, pi, true, Paint()..color = Colors.white.withOpacity(0.85));
        canvas.drawCircle(Offset(cx, cy + r * 0.48), r * 0.13, fill);
        canvas.drawCircle(Offset(cx, cy - r * 0.48), r * 0.13, Paint()..color = Colors.white.withOpacity(0.85));
      case 'divine_eye':
        // 高台教 - Divine Eye
        final eyePath = Path()
          ..moveTo(cx - w * 0.38, cy)
          ..quadraticBezierTo(cx, cy - h * 0.35, cx + w * 0.38, cy)
          ..quadraticBezierTo(cx, cy + h * 0.35, cx - w * 0.38, cy);
        canvas.drawPath(eyePath, fill);
        canvas.drawCircle(Offset(cx, cy), w * 0.15, Paint()..color = const Color(0xFF050816));
        // Radiating lines
        for (int i = 0; i < 12; i++) {
          final a = i * pi / 6;
          canvas.drawLine(
            Offset(cx + w * 0.2 * cos(a), cy + w * 0.2 * sin(a)),
            Offset(cx + w * 0.38 * cos(a), cy + w * 0.38 * sin(a)),
            Paint()..color = color.withOpacity(0.5)..strokeWidth = w * 0.03..strokeCap = StrokeCap.round,
          );
        }
      default:
        // 默认渐变圆点
        final r = w * 0.3;
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
        canvas.drawRect(rect, Paint()
          ..shader = SweepGradient(colors: [
            Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
            Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF),
            Color(0xFF9D4EDD), Color(0xFFFF4D6D),
          ]).createShader(rect));
    }
  }

  @override
  bool shouldRepaint(covariant _ReligionIconPainter old) =>
      shape != old.shape || color != old.color;
}
