import 'dart:math';
import 'package:flutter/material.dart';

/// 宗教图标组件 - 严格对齐网页版 ReligionIcon.tsx
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
    final s = w / 24.0;
    final fill = Paint()..color = color;
    final fillDark = Paint()..color = const Color(0xFF0A0C1A);
    double v(double val) => val * s;

    switch (shape) {
      case 'cross':
        fill.style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(9), v(2), v(6), v(20)), Radius.circular(v(1))), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(4), v(7), v(16), v(6)), Radius.circular(v(1))), fill);
        break;

      case 'papal_cross':
        final bw = v(4);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(10), v(1), bw, v(22)), Radius.circular(v(0.5))), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(4), v(5), v(16), bw), Radius.circular(v(0.5))), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(6), v(10), v(12), v(3.5)), Radius.circular(v(0.5))),
            Paint()..color = color.withOpacity(0.8));
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(8), v(15), v(8), v(3)), Radius.circular(v(0.5))),
            Paint()..color = color.withOpacity(0.6));
        break;

      case 'orthodox_cross':
        final bw = v(4);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(10), v(1), bw, v(22)), Radius.circular(v(0.5))), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(4), v(6), v(16), bw), Radius.circular(v(0.5))), fill);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(6), v(11), v(12), v(3)), Radius.circular(v(0.5))), fill);
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2)..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(v(16), v(14)), Offset(v(19), v(18)), stroke);
        break;

      case 'crescent':
        final r = v(9);
        final outer = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        final inner = Path()..addOval(Rect.fromCircle(
            center: Offset(cx + r * 0.33, cy - r * 0.06), radius: r * 0.78));
        canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), fill);
        canvas.drawCircle(Offset(v(18), v(8)), v(1.5), fill);
        break;

      case 'star_of_david':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5)..strokeCap = StrokeCap.round;
        final up = Path()
          ..moveTo(cx, v(2))
          ..lineTo(v(3.34), v(17))
          ..lineTo(v(20.66), v(17))
          ..close();
        final dn = Path()
          ..moveTo(cx, v(22))
          ..lineTo(v(3.34), v(7))
          ..lineTo(v(20.66), v(7))
          ..close();
        canvas.drawPath(up, stroke);
        canvas.drawPath(dn, stroke);
        break;

      case 'lotus':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        // 底座椭圆
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, v(19)), width: v(16), height: v(4)),
            Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = v(1));
        // 外层花瓣
        stroke.strokeWidth = v(1.5);
        canvas.drawPath(Path()
          ..moveTo(v(4), v(15))
          ..quadraticBezierTo(v(6), v(8), cx, v(6))
          ..quadraticBezierTo(v(18), v(8), v(20), v(15)), stroke);
        // 更外层
        canvas.drawPath(Path()
          ..moveTo(v(2), v(14))
          ..quadraticBezierTo(v(5), v(5), cx, v(3))
          ..quadraticBezierTo(v(19), v(5), v(22), v(14)),
            Paint()..color = color.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = v(1)..strokeCap = StrokeCap.round);
        // 中层
        final mid = Path()
          ..moveTo(v(6), v(15))
          ..quadraticBezierTo(v(8), v(10), cx, v(8))
          ..quadraticBezierTo(v(16), v(10), v(18), v(15))
          ..close();
        canvas.drawPath(mid, Paint()..color = color.withOpacity(0.2));
        canvas.drawPath(mid, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5)..strokeCap = StrokeCap.round);
        // 内层
        final inner = Path()
          ..moveTo(v(8), v(14))
          ..quadraticBezierTo(v(10), v(10), cx, v(9))
          ..quadraticBezierTo(v(14), v(10), v(16), v(14))
          ..close();
        canvas.drawPath(inner, Paint()..color = color.withOpacity(0.3));
        canvas.drawPath(inner, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5)..strokeCap = StrokeCap.round);
        // 中心
        canvas.drawCircle(Offset(cx, v(12)), v(1.5), fill);
        break;

      case 'om':
        final tp = TextPainter(
          text: TextSpan(
            text: 'ॐ',
            style: TextStyle(color: color, fontSize: v(18), fontWeight: FontWeight.bold, fontFamily: 'serif'),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: v(24));
        tp.paint(canvas, Offset(v(3), v(1)));
        break;

      case 'yin_yang':
        final r = v(9);
        canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        final yinPath = Path()
          ..moveTo(cx, v(3))
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), -pi / 2, pi, false)
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy - r / 2), radius: r / 2), pi / 2, -pi, false)
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy + r / 2), radius: r / 2), pi / 2, pi, false)
          ..close();
        canvas.drawPath(yinPath, fill);
        canvas.drawCircle(Offset(cx, v(7.5)), v(1.5), fillDark);
        canvas.drawCircle(Offset(cx, v(16.5)), v(1.5), fill);
        break;

      case 'khanda':
        canvas.drawCircle(Offset(cx, cy), v(9), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(v(10.5), v(2), v(3), v(14)), Radius.circular(v(1))), fill);
        canvas.drawPath(Path()
          ..moveTo(v(7), v(8))
          ..lineTo(cx, v(5))
          ..lineTo(v(17), v(8)),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5)..strokeCap = StrokeCap.round);
        canvas.drawCircle(Offset(cx, v(18)), v(2), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        break;

      case 'star9':
      case 'star5':
        final n = shape == 'star9' ? 9 : 5;
        final r = v(9);
        final p = Path();
        for (int i = 0; i < n; i++) {
          final a = (i * 2 * pi / n) - pi / 2;
          final px = cx + r * cos(a);
          final py = cy + r * sin(a);
          i == 0 ? p.moveTo(px, py) : p.lineTo(px, py);
        }
        p.close();
        canvas.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        break;

      case 'torii':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        stroke.strokeWidth = v(2);
        canvas.drawPath(Path()
          ..moveTo(v(2), v(6))
          ..quadraticBezierTo(cx, v(4), v(22), v(6)), stroke);
        stroke.strokeWidth = v(1.5);
        canvas.drawPath(Path()
          ..moveTo(v(4), v(8))
          ..quadraticBezierTo(cx, v(7), v(20), v(8)), stroke);
        canvas.drawRect(Rect.fromLTWH(v(9), v(7), v(1.5), v(14)), fill);
        canvas.drawRect(Rect.fromLTWH(v(13.5), v(7), v(1.5), v(14)), fill);
        break;

      case 'faravahar':
        canvas.drawPath(Path()
          ..moveTo(cx, v(2))
          ..cubicTo(v(7), v(8), v(7), v(13), v(7), v(13))
          ..cubicTo(v(7), v(17), v(9.5), v(21), cx, v(21))
          ..cubicTo(v(14.5), v(21), v(17), v(17), v(17), v(13))
          ..cubicTo(v(17), v(8), cx, v(2), cx, v(2))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawPath(Path()
          ..moveTo(cx, v(8))
          ..cubicTo(v(10), v(11), v(10), v(13.5), v(10), v(13.5))
          ..cubicTo(v(10), v(15.5), v(11), v(17), cx, v(17))
          ..cubicTo(v(13), v(17), v(14), v(15.5), v(14), v(13.5))
          ..cubicTo(v(14), v(11), cx, v(8), cx, v(8))
          ..close(),
            Paint()..color = color.withOpacity(0.4));
        break;

      case 'sun':
        canvas.drawCircle(Offset(cx, cy), v(4), fill);
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2)..strokeCap = StrokeCap.round;
        for (int deg = 0; deg < 360; deg += 45) {
          final rad = deg * pi / 180;
          canvas.drawLine(
              Offset(cx + v(5.5) * cos(rad), cy + v(5.5) * sin(rad)),
              Offset(cx + v(8) * cos(rad), cy + v(8) * sin(rad)), stroke);
        }
        break;

      case 'eye':
        canvas.drawPath(Path()
          ..moveTo(v(1), cy)
          ..cubicTo(v(1), cy, v(5), v(5), cx, v(5))
          ..cubicTo(v(19), v(5), v(23), cy, v(23), cy)
          ..cubicTo(v(23), cy, v(19), v(19), cx, v(19))
          ..cubicTo(v(5), v(19), v(1), cy, v(1), cy),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawCircle(Offset(cx, cy), v(3.5), fill);
        canvas.drawCircle(Offset(cx, cy), v(1.5), fillDark);
        break;

      case 'spiral':
        final sp = Path();
        for (int i = 0; i <= 50; i++) {
          final t = i / 50 * 2.5 * pi;
          final r = v(1) * (i / 50) * 9;
          final x = cx + r * cos(t);
          final y = cy + r * sin(t);
          i == 0 ? sp.moveTo(x, y) : sp.lineTo(x, y);
        }
        canvas.drawPath(sp, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5)..strokeCap = StrokeCap.round);
        break;

      case 'pyramid':
        canvas.drawPath(Path()
          ..moveTo(cx, v(3))
          ..lineTo(v(22), v(20))
          ..lineTo(v(2), v(20))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawLine(Offset(v(7), v(12)), Offset(v(17), v(12)),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1));
        break;

      case 'wave':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2)..strokeCap = StrokeCap.round;
        canvas.drawPath(Path()
          ..moveTo(v(2), v(10))
          ..cubicTo(v(4), v(8), v(6), v(8), v(8), v(10))
          ..cubicTo(v(10), v(12), v(12), v(12), v(14), v(10))
          ..cubicTo(v(16), v(8), v(18), v(8), v(20), v(10))
          ..cubicTo(v(22), v(12), v(22), v(12), v(22), v(12)), stroke);
        canvas.drawPath(Path()
          ..moveTo(v(2), v(15))
          ..cubicTo(v(4), v(13), v(6), v(13), v(8), v(15))
          ..cubicTo(v(10), v(17), v(12), v(17), v(14), v(15))
          ..cubicTo(v(16), v(13), v(18), v(13), v(20), v(15))
          ..cubicTo(v(22), v(17), v(22), v(17), v(22), v(17)), stroke);
        break;

      case 'jain_hand':
        canvas.drawPath(Path()
          ..moveTo(cx, v(22))
          ..cubicTo(cx - v(4), v(19), cx - v(7), v(16), cx - v(7), v(12))
          ..cubicTo(cx - v(7), v(10), cx - v(6), v(9), cx - v(5), v(9))
          ..cubicTo(cx - v(4), v(9), cx - v(3), v(10), cx - v(3), v(11))
          ..lineTo(cx - v(3), v(8))
          ..cubicTo(cx - v(3), v(7), cx - v(2), v(6), cx - v(1), v(6))
          ..cubicTo(cx, v(6), cx, v(7), cx, v(8))
          ..lineTo(cx, v(8))
          ..cubicTo(cx, v(7), cx + v(1), v(6), cx + v(2), v(6))
          ..cubicTo(cx + v(3), v(6), cx + v(3), v(7), cx + v(3), v(8))
          ..lineTo(cx + v(3), v(9))
          ..cubicTo(cx + v(3), v(8), cx + v(4), v(7), cx + v(5), v(7))
          ..cubicTo(cx + v(6), v(7), cx + v(6), v(8), cx + v(6), v(9))
          ..lineTo(cx + v(6), v(10))
          ..cubicTo(cx + v(6), v(9), cx + v(7), v(8), cx + v(7), v(9))
          ..cubicTo(cx + v(7), v(10), cx + v(7), v(11), cx + v(7), v(12))
          ..cubicTo(cx + v(7), v(16), cx + v(4), v(19), cx, v(22))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawCircle(Offset(cx, v(15)), v(3), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1));
        canvas.drawCircle(Offset(cx, v(15)), v(1), fill);
        break;

      case 'snake':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2)..strokeCap = StrokeCap.round;
        final dashPath = Path();
        final circleR = v(8);
        final circumference = 2 * pi * circleR;
        final dashLen = circumference / 10;
        final gapLen = circumference / 10;
        final totalLen = dashLen + gapLen;
        for (double start = 0; start < circumference; start += totalLen) {
          final a1 = start / circleR;
          final a2 = (start + dashLen) / circleR;
          dashPath.addArc(Rect.fromCircle(center: Offset(cx, cy), radius: circleR), a1, a2 - a1);
        }
        canvas.drawPath(dashPath, stroke);
        canvas.drawCircle(Offset(cx, v(4)), v(2.5), fill);
        break;

      case 'tree':
        canvas.drawRect(Rect.fromLTWH(v(11), v(16), v(2), v(6)), fill);
        canvas.drawPath(Path()
          ..moveTo(cx, v(4))
          ..lineTo(v(7), v(10))
          ..lineTo(v(10), v(10))
          ..lineTo(v(8), v(14))
          ..lineTo(v(10), v(14))
          ..lineTo(cx, v(16))
          ..lineTo(v(14), v(14))
          ..lineTo(v(16), v(14))
          ..lineTo(v(14), v(10))
          ..lineTo(v(17), v(10))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        break;

      case 'angel':
        canvas.drawCircle(Offset(cx, v(6)), v(2.5), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawPath(Path()
          ..moveTo(v(8), v(10))
          ..lineTo(v(16), v(10))
          ..lineTo(v(14), v(18))
          ..lineTo(v(10), v(18))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2)..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(v(16), v(9)), Offset(v(20), v(6)), stroke);
        canvas.drawPath(Path()
          ..moveTo(v(20), v(4))
          ..lineTo(v(22), v(5))
          ..lineTo(v(20), v(6))
          ..close(), fill);
        break;

      case 'tower':
        canvas.drawPath(Path()
          ..moveTo(v(8), v(22))
          ..lineTo(v(9), v(8))
          ..lineTo(v(15), v(8))
          ..lineTo(v(16), v(22))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawPath(Path()
          ..moveTo(v(9), v(8))
          ..lineTo(v(10), v(3))
          ..lineTo(v(14), v(3))
          ..lineTo(v(15), v(8)),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawRect(Rect.fromLTWH(v(11), v(14), v(2), v(3)), fill);
        break;

      case 'crown':
        canvas.drawPath(Path()
          ..moveTo(v(3), v(18))
          ..lineTo(v(5), v(8))
          ..lineTo(v(9), v(13))
          ..lineTo(cx, v(6))
          ..lineTo(v(15), v(13))
          ..lineTo(v(19), v(8))
          ..lineTo(v(21), v(18))
          ..close(),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawLine(Offset(v(3), v(18)), Offset(v(21), v(18)),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2));
        break;

      case 'taeguk':
        final r = v(9);
        canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        final taegukPath = Path()
          ..moveTo(cx, v(3))
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), -pi / 2, pi, false)
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy + r / 2), radius: r / 2), pi / 2, -pi, false)
          ..arcTo(Rect.fromCircle(center: Offset(cx, cy - r / 2), radius: r / 2), pi / 2, pi, false)
          ..close();
        canvas.drawPath(taegukPath, fill);
        break;

      case 'divine_eye':
        canvas.drawPath(Path()
          ..moveTo(v(1), cy)
          ..cubicTo(v(1), cy, v(5), v(5), cx, v(5))
          ..cubicTo(v(19), v(5), v(23), cy, v(23), cy)
          ..cubicTo(v(23), cy, v(19), v(19), cx, v(19))
          ..cubicTo(v(5), v(19), v(1), cy, v(1), cy),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawCircle(Offset(cx, cy), v(4), fill);
        canvas.drawCircle(Offset(cx, cy), v(1.5), fillDark);
        break;

      case 'circle':
        canvas.drawCircle(Offset(cx, cy), v(8), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(2));
        canvas.drawCircle(Offset(cx, cy), v(3), fill);
        break;

      case 'book':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5);
        canvas.drawPath(Path()
          ..moveTo(v(2), v(4))
          ..cubicTo(v(2), v(4), v(4), v(4), v(8), v(6))
          ..lineTo(v(8), v(20))
          ..cubicTo(v(7), v(19), v(2), v(19), v(2), v(19))
          ..close(), stroke);
        canvas.drawPath(Path()
          ..moveTo(v(22), v(4))
          ..cubicTo(v(22), v(4), v(20), v(4), v(16), v(6))
          ..lineTo(v(16), v(20))
          ..cubicTo(v(17), v(19), v(22), v(19), v(22), v(19))
          ..close(), stroke);
        stroke.strokeWidth = v(1);
        canvas.drawLine(Offset(cx, v(6)), Offset(cx, v(20)), stroke);
        break;

      case 'scroll':
        final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5);
        canvas.drawPath(Path()
          ..moveTo(v(4), v(5))
          ..cubicTo(v(4), v(5), v(6), v(3), v(6), v(5))
          ..lineTo(v(6), v(19))
          ..cubicTo(v(6), v(21), v(4), v(19), v(4), v(19)), stroke);
        canvas.drawPath(Path()
          ..moveTo(v(20), v(5))
          ..cubicTo(v(20), v(5), v(18), v(3), v(18), v(5))
          ..lineTo(v(18), v(19))
          ..cubicTo(v(18), v(21), v(20), v(19), v(20), v(19)), stroke);
        canvas.drawRect(Rect.fromLTWH(v(6), v(5), v(12), v(14)),
            Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = v(1));
        final linePaint = Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = v(1);
        canvas.drawLine(Offset(v(8), v(9)), Offset(v(16), v(9)), linePaint);
        canvas.drawLine(Offset(v(8), v(12)), Offset(v(16), v(12)), linePaint);
        canvas.drawLine(Offset(v(8), v(15)), Offset(v(14), v(15)), linePaint);
        break;

      case 'compass':
        canvas.drawCircle(Offset(cx, cy), v(9), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        canvas.drawPath(Path()
          ..moveTo(cx, v(4))
          ..lineTo(cx + v(2), v(11))
          ..lineTo(cx, v(10))
          ..lineTo(cx - v(2), v(11))
          ..close(), Paint()..color = color.withOpacity(0.8));
        canvas.drawPath(Path()
          ..moveTo(cx, v(20))
          ..lineTo(cx - v(2), v(13))
          ..lineTo(cx, v(14))
          ..lineTo(cx + v(2), v(13))
          ..close(), Paint()..color = color.withOpacity(0.4));
        canvas.drawCircle(Offset(cx, cy), v(1), fill);
        break;

      default:
        canvas.drawPath(Path()
          ..moveTo(v(6.5), v(2))
          ..lineTo(v(20), v(2))
          ..lineTo(v(20), v(22))
          ..lineTo(v(6.5), v(22))
          ..arcTo(Rect.fromLTWH(v(4), v(17), v(5), v(5)), pi / 2, pi, false),
            Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = v(1.5));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ReligionIconPainter old) =>
      shape != old.shape || color != old.color;
}
