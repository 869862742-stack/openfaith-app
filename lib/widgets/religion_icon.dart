import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 宗教图标组件 - 严格对齐网页版 ReligionIcon.tsx SVG
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

/// 获取宗教图标配置 (shape, color)
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

  /// Convert SVG 24-based coordinate to actual size
  double sx(double svgX, double w) => w * svgX / 24;
  double sy(double svgY, double h) => h * svgY / 24;
  double sr(double svgR, double w) => w * svgR / 24;
  double sw(double svgW, double w) => w * svgW / 24;
  double sh(double svgH, double h) => h * svgH / 24;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (shape) {
      // ============ cross: rect竖条 + rect横条, fill ============
      case 'cross':
        canvas.drawRect(
          Rect.fromLTWH(sx(9, w), sy(2, h), sw(6, w), sh(20, h)),
          fillPaint,
        );
        // top-left / top-right rounded corners via clip
        canvas.drawRect(
          Rect.fromLTWH(sx(4, w), sy(7, h), sw(16, w), sh(6, h)),
          fillPaint,
        );

      // ============ papal_cross: rect竖条 + 三横（递减宽度，opacity递减）============
      case 'papal_cross':
        canvas.drawRect(
          Rect.fromLTWH(sx(10, w), sy(1, h), sw(4, w), sh(22, h)),
          fillPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(sx(4, w), sy(5, h), sw(16, w), sh(4, h)),
          fillPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(sx(6, w), sy(10, h), sw(12, w), sh(3.5, h)),
          Paint()..color = color.withOpacity(0.8)..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          Rect.fromLTWH(sx(8, w), sy(15, h), sw(8, w), sh(3, h)),
          Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill,
        );

      // ============ orthodox_cross: rect竖条 + 两横 + 斜线 ============
      case 'orthodox_cross':
        canvas.drawRect(
          Rect.fromLTWH(sx(10, w), sy(1, h), sw(4, w), sh(22, h)),
          fillPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(sx(4, w), sy(6, h), sw(16, w), sh(4, h)),
          fillPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(sx(6, w), sy(11, h), sw(12, w), sh(3, h)),
          fillPaint,
        );
        // 斜线 (line x1=16 y1=14 x2=19 y2=18)
        strokePaint.strokeWidth = sw(2, w);
        canvas.drawLine(
          Offset(sx(16, w), sy(14, h)),
          Offset(sx(19, w), sy(18, h)),
          strokePaint,
        );

      // ============ crescent: 月牙 + 小圆点 ============
      case 'crescent':
        final crescentPath = Path();
        // M12 3C7.03 3 3 7.03 3 12s4.03 9 9 9c1.5 0 2.91-.37 4.15-1.01C13.55 18.37 12 15.87 12 13c0-2.87 1.55-5.37 4.15-6.99C14.91 3.37 13.5 3 12 3z
        crescentPath.moveTo(sx(12, w), sy(3, h));
        crescentPath.cubicTo(sx(7.03, w), sy(3, h), sx(3, w), sy(7.03, h), sx(3, w), sy(12, h));
        crescentPath.cubicTo(sx(3, w), sy(16.97, h), sx(7.03, w), sy(21, h), sx(12, w), sy(21, h));
        crescentPath.cubicTo(sx(13.5, w), sy(21, h), sx(14.91, w), sy(20.63, h), sx(16.15, w), sy(19.99, h));
        crescentPath.cubicTo(sx(13.55, w), sy(18.37, h), sx(12, w), sy(15.87, h), sx(12, w), sy(13, h));
        crescentPath.cubicTo(sx(12, w), sy(10.13, h), sx(13.55, w), sy(7.63, h), sx(16.15, w), sy(6.01, h));
        crescentPath.cubicTo(sx(14.91, w), sy(3.37, h), sx(13.5, w), sy(3, h), sx(12, w), sy(3, h));
        crescentPath.close();
        canvas.drawPath(crescentPath, fillPaint);
        // circle cx=18 cy=8 r=1.5
        canvas.drawCircle(Offset(sx(18, w), sy(8, h)), sr(1.5, w), fillPaint);

      // ============ star_of_david: 两个三角形 STROKE ============
      case 'star_of_david':
        strokePaint.strokeWidth = sw(1.5, w);
        // 上三角: M12 2l8.66 15H3.34L12 2z
        final upPath = Path()
          ..moveTo(sx(12, w), sy(2, h))
          ..lineTo(sx(20.66, w), sy(17, h))
          ..lineTo(sx(3.34, w), sy(17, h))
          ..close();
        canvas.drawPath(upPath, strokePaint);
        // 下三角: M12 22l-8.66-15h17.32L12 22z
        final dnPath = Path()
          ..moveTo(sx(12, w), sy(22, h))
          ..lineTo(sx(3.34, w), sy(7, h))
          ..lineTo(sx(20.66, w), sy(7, h))
          ..close();
        canvas.drawPath(dnPath, strokePaint);

      // ============ lotus: ellipse底座 + 多层path花瓣 + 中心圆点 ============
      case 'lotus':
        // 底座椭圆 ellipse cx=12 cy=19 rx=8 ry=2, stroke, opacity 0.4
        canvas.drawOval(
          Rect.fromCenter(center: Offset(sx(12, w), sy(19, h)), width: sw(16, w), height: sh(4, h)),
          Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = sw(1, w),
        );
        // 外层花瓣1: M4 15C4 15 6 8 12 6C18 8 20 15 20 15
        final petal1 = Path()
          ..moveTo(sx(4, w), sy(15, h))
          ..cubicTo(sx(4, w), sy(15, h), sx(6, w), sy(8, h), sx(12, w), sy(6, h))
          ..cubicTo(sx(18, w), sy(8, h), sx(20, w), sy(15, h), sx(20, w), sy(15, h));
        canvas.drawPath(petal1, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw(1.5, w));
        // 外层花瓣2: M2 14... opacity 0.5
        final petal2 = Path()
          ..moveTo(sx(2, w), sy(14, h))
          ..cubicTo(sx(2, w), sy(14, h), sx(5, w), sy(5, h), sx(12, w), sy(3, h))
          ..cubicTo(sx(19, w), sy(5, h), sx(22, w), sy(14, h), sx(22, w), sy(14, h));
        canvas.drawPath(petal2, Paint()..color = color.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = sw(1, w));
        // 中层花瓣: M6 15... fill opacity 0.2
        final petal3 = Path()
          ..moveTo(sx(6, w), sy(15, h))
          ..cubicTo(sx(6, w), sy(15, h), sx(8, w), sy(10, h), sx(12, w), sy(8, h))
          ..cubicTo(sx(16, w), sy(10, h), sx(18, w), sy(15, h), sx(18, w), sy(15, h));
        canvas.drawPath(petal3, Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.fill);
        canvas.drawPath(petal3, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw(1.5, w));
        // 内层花瓣: M8 14... fill opacity 0.3
        final petal4 = Path()
          ..moveTo(sx(8, w), sy(14, h))
          ..cubicTo(sx(8, w), sy(14, h), sx(10, w), sy(10, h), sx(12, w), sy(9, h))
          ..cubicTo(sx(14, w), sy(10, h), sx(16, w), sy(14, h), sx(16, w), sy(14, h));
        canvas.drawPath(petal4, Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.fill);
        canvas.drawPath(petal4, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw(1.5, w));
        // 中心点 circle cx=12 cy=12 r=1.5
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(1.5, w), fillPaint);

      // ============ om: ॐ 梵文字符 via TextPainter ============
      case 'om':
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'ॐ',
            style: TextStyle(
              color: color,
              fontSize: sw(18, w),
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        // Position: x=3, y=19 in SVG (baseline). Adjust for top-left.
        final offsetX = sx(3, w);
        final offsetY = sy(19, h) - textPainter.height + textPainter.preferredLineHeight * 0.2;
        textPainter.paint(canvas, Offset(offsetX, offsetY));

      // ============ yin_yang: circle外圈 + path半填充 + 两个小圆点 ============
      case 'yin_yang':
        final r = sr(9, w);
        final center = Offset(sx(12, w), sy(12, h));
        // 外圈 stroke
        canvas.drawCircle(center, r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw(1.5, w));
        // 半填充 path: M12 3A9 9 0 0 1 12 21A4.5 4.5 0 0 1 12 12A4.5 4.5 0 0 0 12 3z
        final yyPath = Path()
          ..moveTo(sx(12, w), sy(3, h))
          ..arcToPoint(Offset(sx(12, w), sy(21, h)), radius: Radius.circular(r), clockwise: true)
          ..arcToPoint(Offset(sx(12, w), sy(12, h)), radius: Radius.circular(r / 2), clockwise: true)
          ..arcToPoint(Offset(sx(12, w), sy(3, h)), radius: Radius.circular(r / 2), clockwise: false)
          ..close();
        canvas.drawPath(yyPath, fillPaint);
        // 小圆点 上 (dark) cx=12 cy=7.5 r=1.5
        canvas.drawCircle(Offset(sx(12, w), sy(7.5, h)), sr(1.5, w), Paint()..color = const Color(0xFF0A0C1A)..style = PaintingStyle.fill);
        // 小圆点 下 (color) cx=12 cy=16.5 r=1.5
        canvas.drawCircle(Offset(sx(12, w), sy(16.5, h)), sr(1.5, w), fillPaint);

      // ============ khanda: circle + rect竖条 + path人字V + circle底部 ============
      case 'khanda':
        // circle cx=12 cy=12 r=9 stroke
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(9, w), strokePaint);
        // rect竖条 x=10.5 y=2 width=3 height=14
        canvas.drawRect(
          Rect.fromLTWH(sx(10.5, w), sy(2, h), sw(3, w), sh(14, h)),
          fillPaint,
        );
        // path人字V: M7 8L12 5L17 8 stroke
        final vPath = Path()
          ..moveTo(sx(7, w), sy(8, h))
          ..lineTo(sx(12, w), sy(5, h))
          ..lineTo(sx(17, w), sy(8, h));
        canvas.drawPath(vPath, strokePaint);
        // circle cx=12 cy=18 r=2 stroke
        canvas.drawCircle(Offset(sx(12, w), sy(18, h)), sr(2, w), strokePaint);

      // ============ star9: 9边形polygon STROKE ============
      case 'star9':
        strokePaint.strokeWidth = sw(1.5, w);
        final p = Path();
        for (int i = 0; i < 9; i++) {
          final angle = (i * 40 - 90) * pi / 180;
          final x = sx(12, w) + sr(9, w) * cos(angle);
          final y = sy(12, h) + sr(9, w) * sin(angle);
          i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        p.close();
        canvas.drawPath(p, strokePaint);

      // ============ torii: path两弧线（顶部横梁）+ 两rect柱子 ============
      case 'torii':
        // 上弧线: M2 6C6 4 8 4 12 4C16 4 18 4 22 6
        strokePaint.strokeWidth = sw(2, w);
        final arc1 = Path()
          ..moveTo(sx(2, w), sy(6, h))
          ..cubicTo(sx(6, w), sy(4, h), sx(8, w), sy(4, h), sx(12, w), sy(4, h))
          ..cubicTo(sx(16, w), sy(4, h), sx(18, w), sy(4, h), sx(22, w), sy(6, h));
        canvas.drawPath(arc1, strokePaint);
        // 下弧线: M4 8C8 7 10 7 12 7C14 7 16 7 20 8
        strokePaint.strokeWidth = sw(1.5, w);
        final arc2 = Path()
          ..moveTo(sx(4, w), sy(8, h))
          ..cubicTo(sx(8, w), sy(7, h), sx(10, w), sy(7, h), sx(12, w), sy(7, h))
          ..cubicTo(sx(14, w), sy(7, h), sx(16, w), sy(7, h), sx(20, w), sy(8, h));
        canvas.drawPath(arc2, strokePaint);
        // 左柱 rect x=9 y=7 width=1.5 height=14
        canvas.drawRect(Rect.fromLTWH(sx(9, w), sy(7, h), sw(1.5, w), sh(14, h)), fillPaint);
        // 右柱 rect x=13.5 y=7 width=1.5 height=14
        canvas.drawRect(Rect.fromLTWH(sx(13.5, w), sy(7, h), sw(1.5, w), sh(14, h)), fillPaint);

      // ============ star5: 五角星polygon STROKE ============
      case 'star5':
        strokePaint.strokeWidth = sw(1.5, w);
        // 12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26
        final pts = [
          [12.0, 2.0], [15.09, 8.26], [22.0, 9.27], [17.0, 14.14],
          [18.18, 21.02], [12.0, 17.77], [5.82, 21.02], [7.0, 14.14],
          [2.0, 9.27], [8.91, 8.26],
        ];
        final p = Path();
        for (int i = 0; i < pts.length; i++) {
          final x = sx(pts[i][0], w);
          final y = sy(pts[i][1], h);
          i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
        }
        p.close();
        canvas.drawPath(p, strokePaint);

      // ============ faravahar: 火焰/水滴形 STROKE + 内部opacity填充 ============
      case 'faravahar':
        // 外层火焰: M12 2C12 2 7 8 7 13C7 17 9.5 21 12 21C14.5 21 17 17 17 13C17 8 12 2 12 2z
        final flamePath = Path()
          ..moveTo(sx(12, w), sy(2, h))
          ..cubicTo(sx(12, w), sy(2, h), sx(7, w), sy(8, h), sx(7, w), sy(13, h))
          ..cubicTo(sx(7, w), sy(17, h), sx(9.5, w), sy(21, h), sx(12, w), sy(21, h))
          ..cubicTo(sx(14.5, w), sy(21, h), sx(17, w), sy(17, h), sx(17, w), sy(13, h))
          ..cubicTo(sx(17, w), sy(8, h), sx(12, w), sy(2, h), sx(12, w), sy(2, h))
          ..close();
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawPath(flamePath, strokePaint);
        // 内层火焰: M12 8C12 8 10 11 10 13.5C10 15.5 11 17 12 17C13 17 14 15.5 14 13.5C14 11 12 8 12 8z
        final innerPath = Path()
          ..moveTo(sx(12, w), sy(8, h))
          ..cubicTo(sx(12, w), sy(8, h), sx(10, w), sy(11, h), sx(10, w), sy(13.5, h))
          ..cubicTo(sx(10, w), sy(15.5, h), sx(11, w), sy(17, h), sx(12, w), sy(17, h))
          ..cubicTo(sx(13, w), sy(17, h), sx(14, w), sy(15.5, h), sx(14, w), sy(13.5, h))
          ..cubicTo(sx(14, w), sy(11, h), sx(12, w), sy(8, h), sx(12, w), sy(8, h))
          ..close();
        canvas.drawPath(innerPath, Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.fill);

      // ============ sun: circle中心 + 8条光线 ============
      case 'sun':
        // circle cx=12 cy=12 r=4 fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(4, w), fillPaint);
        // 8条光线: 从5.5到8的8条line
        strokePaint.strokeWidth = sw(2, w);
        for (int i = 0; i < 8; i++) {
          final angle = i * 45 * pi / 180;
          final x1 = sx(12, w) + sr(5.5, w) * cos(angle);
          final y1 = sy(12, h) + sr(5.5, w) * sin(angle);
          final x2 = sx(12, w) + sr(8, w) * cos(angle);
          final y2 = sy(12, h) + sr(8, w) * sin(angle);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), strokePaint);
        }

      // ============ eye: path眼形STROKE + circle虹膜 + circle瞳孔 ============
      case 'eye':
        // 眼形 path: M1 12S5 5 12 5s11 7 11 7-4 7-11 7S1 12 1 12z stroke
        final eyePath = Path()
          ..moveTo(sx(1, w), sy(12, h))
          ..cubicTo(sx(1, w), sy(12, h), sx(5, w), sy(5, h), sx(12, w), sy(5, h))
          ..cubicTo(sx(19, w), sy(5, h), sx(23, w), sy(12, h), sx(23, w), sy(12, h))
          ..cubicTo(sx(23, w), sy(12, h), sx(19, w), sy(19, h), sx(12, w), sy(19, h))
          ..cubicTo(sx(5, w), sy(19, h), sx(1, w), sy(12, h), sx(1, w), sy(12, h));
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawPath(eyePath, strokePaint);
        // circle虹膜 cx=12 cy=12 r=3.5 fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(3.5, w), fillPaint);
        // circle瞳孔 cx=12 cy=12 r=1.5 dark fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(1.5, w), Paint()..color = const Color(0xFF0A0C1A)..style = PaintingStyle.fill);

      // ============ spiral: path连续螺旋线STROKE ============
      case 'spiral':
        // M12 12m-1,0a1,1 0 1,0 2,0a3,3 0 1,0 -6,0a5,5 0 1,0 10,0a7,7 0 1,0 -14,0a9,9 0 1,0 18,0
        // Simplified: draw concentric arc segments
        strokePaint.strokeWidth = sw(1.5, w);
        final spiralPath = Path();
        final cx = sx(12, w), cy = sy(12, h);
        // Draw as a series of arcs
        // r=1: 180° arc from (cx+1, cy) counterclockwise
        spiralPath.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: sr(1, w)), 0, pi, false);
        // r=3: 180° arc
        spiralPath.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: sr(3, w)), pi, pi, false);
        // r=5: 180° arc
        spiralPath.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: sr(5, w)), 0, pi, false);
        // r=7: 180° arc
        spiralPath.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: sr(7, w)), pi, pi, false);
        // r=9: 180° arc
        spiralPath.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: sr(9, w)), 0, pi, false);
        canvas.drawPath(spiralPath, strokePaint);

      // ============ pyramid: path三角形STROKE + 横线 ============
      case 'pyramid':
        // M12 3L22 20H2L12 3z stroke
        strokePaint.strokeWidth = sw(1.5, w);
        final pyrPath = Path()
          ..moveTo(sx(12, w), sy(3, h))
          ..lineTo(sx(22, w), sy(20, h))
          ..lineTo(sx(2, w), sy(20, h))
          ..close();
        canvas.drawPath(pyrPath, strokePaint);
        // 横线 x1=7 y1=12 x2=17 y2=12
        strokePaint.strokeWidth = sw(1, w);
        canvas.drawLine(Offset(sx(7, w), sy(12, h)), Offset(sx(17, w), sy(12, h)), strokePaint);

      // ============ wave: 两条path波浪线STROKE ============
      case 'wave':
        strokePaint.strokeWidth = sw(2, w);
        // 第一条: M2 10C4 8 6 8 8 10C10 12 12 12 14 10C16 8 18 8 20 10C22 12 22 12 22 12
        final wave1 = Path()
          ..moveTo(sx(2, w), sy(10, h))
          ..cubicTo(sx(4, w), sy(8, h), sx(6, w), sy(8, h), sx(8, w), sy(10, h))
          ..cubicTo(sx(10, w), sy(12, h), sx(12, w), sy(12, h), sx(14, w), sy(10, h))
          ..cubicTo(sx(16, w), sy(8, h), sx(18, w), sy(8, h), sx(20, w), sy(10, h))
          ..cubicTo(sx(22, w), sy(12, h), sx(22, w), sy(12, h), sx(22, w), sy(12, h));
        canvas.drawPath(wave1, strokePaint);
        // 第二条: M2 15C4 13 6 13 8 15C10 17 12 17 14 15C16 13 18 13 20 15C22 17 22 17 22 17
        final wave2 = Path()
          ..moveTo(sx(2, w), sy(15, h))
          ..cubicTo(sx(4, w), sy(13, h), sx(6, w), sy(13, h), sx(8, w), sy(15, h))
          ..cubicTo(sx(10, w), sy(17, h), sx(12, w), sy(17, h), sx(14, w), sy(15, h))
          ..cubicTo(sx(16, w), sy(13, h), sx(18, w), sy(13, h), sx(20, w), sy(15, h))
          ..cubicTo(sx(22, w), sy(17, h), sx(22, w), sy(17, h), sx(22, w), sy(17, h));
        canvas.drawPath(wave2, strokePaint);

      // ============ jain_hand: path手掌轮廓STROKE + circle轮 + circle中心点 ============
      case 'jain_hand':
        // 手掌: M12 22c-4-3-7-6-7-10 0-2 1-3 2-3s2 1 2 2V8c0-1 1-2 2-2s2 1 2 2v2c0-1 1-2 2-2s2 1 2 2v1c0-1 1-2 2-2s2 1 2 3c0 4-3 7-7 10z
        final handPath = Path()
          ..moveTo(sx(12, w), sy(22, h))
          ..cubicTo(sx(8, w), sy(19, h), sx(5, w), sy(16, h), sx(5, w), sy(12, h))
          ..cubicTo(sx(5, w), sy(10, h), sx(6, w), sy(9, h), sx(7, w), sy(9, h))
          ..cubicTo(sx(8, w), sy(9, h), sx(9, w), sy(10, h), sx(9, w), sy(11, h))
          ..lineTo(sx(9, w), sy(8, h))
          ..cubicTo(sx(9, w), sy(7, h), sx(10, w), sy(6, h), sx(11, w), sy(6, h))
          ..cubicTo(sx(12, w), sy(6, h), sx(13, w), sy(7, h), sx(13, w), sy(8, h))
          ..lineTo(sx(13, w), sy(10, h))
          ..cubicTo(sx(13, w), sy(9, h), sx(14, w), sy(8, h), sx(15, w), sy(8, h))
          ..cubicTo(sx(16, w), sy(8, h), sx(17, w), sy(9, h), sx(17, w), sy(10, h))
          ..lineTo(sx(17, w), sy(11, h))
          ..cubicTo(sx(17, w), sy(10, h), sx(18, w), sy(9, h), sx(19, w), sy(9, h))
          ..cubicTo(sx(20, w), sy(9, h), sx(21, w), sy(10, h), sx(21, w), sy(12, h))
          ..cubicTo(sx(21, w), sy(16, h), sx(18, w), sy(19, h), sx(12, w), sy(22, h))
          ..close();
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawPath(handPath, strokePaint);
        // circle轮 cx=12 cy=15 r=3 stroke
        canvas.drawCircle(Offset(sx(12, w), sy(15, h)), sr(3, w), Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = sw(1, w));
        // circle中心点 cx=12 cy=15 r=1 fill
        canvas.drawCircle(Offset(sx(12, w), sy(15, h)), sr(1, w), fillPaint);

      // ============ snake: 虚线圆 + 头部圆点 ============
      case 'snake':
        // 虚线圆 cx=12 cy=12 r=8, strokeDasharray="4 2"
        final snakePaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw(2, w);
        // Draw dashed circle manually
        final dashLen = sw(4, w);
        final gapLen = sw(2, w);
        final totalLen = 2 * pi * sr(8, w);
        final segmentLen = dashLen + gapLen;
        final segments = (totalLen / segmentLen).floor();
        for (int i = 0; i < segments; i++) {
          final startAngle = (i * segmentLen / totalLen) * 2 * pi;
          final sweepAngle = (dashLen / totalLen) * 2 * pi;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(sx(12, w), sy(12, h)), radius: sr(8, w)),
            startAngle,
            sweepAngle,
            false,
            snakePaint,
          );
        }
        // 头部圆点 cx=12 cy=4 r=2.5 fill
        canvas.drawCircle(Offset(sx(12, w), sy(4, h)), sr(2.5, w), fillPaint);

      // ============ tree: rect树干 + path树枝(闪电形)STROKE ============
      case 'tree':
        // 树干 rect x=11 y=16 width=2 height=6
        canvas.drawRect(Rect.fromLTWH(sx(11, w), sy(16, h), sw(2, w), sh(6, h)), fillPaint);
        // 树枝(闪电形): M12 4L7 10H10L8 14H10L12 16L14 14H16L14 10H17L12 4z
        strokePaint.strokeWidth = sw(1.5, w);
        final treePath = Path()
          ..moveTo(sx(12, w), sy(4, h))
          ..lineTo(sx(7, w), sy(10, h))
          ..lineTo(sx(10, w), sy(10, h))
          ..lineTo(sx(8, w), sy(14, h))
          ..lineTo(sx(10, w), sy(14, h))
          ..lineTo(sx(12, w), sy(16, h))
          ..lineTo(sx(14, w), sy(14, h))
          ..lineTo(sx(16, w), sy(14, h))
          ..lineTo(sx(14, w), sy(10, h))
          ..lineTo(sx(17, w), sy(10, h))
          ..close();
        canvas.drawPath(treePath, strokePaint);

      // ============ angel: circle头STROKE + path身体STROKE + path号角线 + path号角头 ============
      case 'angel':
        // 头 circle cx=12 cy=6 r=2.5 stroke
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawCircle(Offset(sx(12, w), sy(6, h)), sr(2.5, w), strokePaint);
        // 身体: M8 10H16L14 18H10L8 10z stroke
        final bodyPath = Path()
          ..moveTo(sx(8, w), sy(10, h))
          ..lineTo(sx(16, w), sy(10, h))
          ..lineTo(sx(14, w), sy(18, h))
          ..lineTo(sx(10, w), sy(18, h))
          ..close();
        canvas.drawPath(bodyPath, strokePaint);
        // 号角线: M16 9L20 6 stroke
        strokePaint.strokeWidth = sw(2, w);
        canvas.drawLine(Offset(sx(16, w), sy(9, h)), Offset(sx(20, w), sy(6, h)), strokePaint);
        // 号角头: M20 4L22 5L20 6 fill
        final hornPath = Path()
          ..moveTo(sx(20, w), sy(4, h))
          ..lineTo(sx(22, w), sy(5, h))
          ..lineTo(sx(20, w), sy(6, h))
          ..close();
        canvas.drawPath(hornPath, fillPaint);

      // ============ tower: path梯形底STROKE + path尖顶STROKE + rect窗户 ============
      case 'tower':
        // 梯形底: M8 22L9 8H15L16 22H8z stroke
        strokePaint.strokeWidth = sw(1.5, w);
        final base = Path()
          ..moveTo(sx(8, w), sy(22, h))
          ..lineTo(sx(9, w), sy(8, h))
          ..lineTo(sx(15, w), sy(8, h))
          ..lineTo(sx(16, w), sy(22, h))
          ..close();
        canvas.drawPath(base, strokePaint);
        // 尖顶: M9 8L10 3H14L15 8 stroke
        final roof = Path()
          ..moveTo(sx(9, w), sy(8, h))
          ..lineTo(sx(10, w), sy(3, h))
          ..lineTo(sx(14, w), sy(3, h))
          ..lineTo(sx(15, w), sy(8, h));
        canvas.drawPath(roof, strokePaint);
        // 窗户 rect x=11 y=14 width=2 height=3 fill
        canvas.drawRect(Rect.fromLTWH(sx(11, w), sy(14, h), sw(2, w), sh(3, h)), fillPaint);

      // ============ crown: path冠形STROKE + 底线 ============
      case 'crown':
        // M3 18L5 8L9 13L12 6L15 13L19 8L21 18H3z stroke
        strokePaint.strokeWidth = sw(1.5, w);
        final crownPath = Path()
          ..moveTo(sx(3, w), sy(18, h))
          ..lineTo(sx(5, w), sy(8, h))
          ..lineTo(sx(9, w), sy(13, h))
          ..lineTo(sx(12, w), sy(6, h))
          ..lineTo(sx(15, w), sy(13, h))
          ..lineTo(sx(19, w), sy(8, h))
          ..lineTo(sx(21, w), sy(18, h))
          ..close();
        canvas.drawPath(crownPath, strokePaint);
        // 底线 x1=3 y1=18 x2=21 y2=18
        strokePaint.strokeWidth = sw(2, w);
        canvas.drawLine(Offset(sx(3, w), sy(18, h)), Offset(sx(21, w), sy(18, h)), strokePaint);

      // ============ taeguk: circle外圈 + path S曲线填充 ============
      case 'taeguk':
        // circle cx=12 cy=12 r=9 stroke
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(9, w), strokePaint);
        // S曲线: M12 3A4.5 4.5 0 0 0 12 12A4.5 4.5 0 0 1 12 21A9 9 0 0 1 12 3z fill
        final taegukPath = Path()
          ..moveTo(sx(12, w), sy(3, h))
          ..arcToPoint(Offset(sx(12, w), sy(12, h)), radius: Radius.circular(sr(4.5, w)), clockwise: false)
          ..arcToPoint(Offset(sx(12, w), sy(21, h)), radius: Radius.circular(sr(4.5, w)), clockwise: true)
          ..arcToPoint(Offset(sx(12, w), sy(3, h)), radius: Radius.circular(sr(9, w)), clockwise: false)
          ..close();
        canvas.drawPath(taegukPath, fillPaint);

      // ============ divine_eye: path眼形STROKE + circle(r=4)填充 + circle瞳孔 ============
      case 'divine_eye':
        // 眼形 path: M1 12S5 5 12 5s11 7 11 7-4 7-11 7S1 12 1 12z stroke
        final deyePath = Path()
          ..moveTo(sx(1, w), sy(12, h))
          ..cubicTo(sx(1, w), sy(12, h), sx(5, w), sy(5, h), sx(12, w), sy(5, h))
          ..cubicTo(sx(19, w), sy(5, h), sx(23, w), sy(12, h), sx(23, w), sy(12, h))
          ..cubicTo(sx(23, w), sy(12, h), sx(19, w), sy(19, h), sx(12, w), sy(19, h))
          ..cubicTo(sx(5, w), sy(19, h), sx(1, w), sy(12, h), sx(1, w), sy(12, h));
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawPath(deyePath, strokePaint);
        // circle cx=12 cy=12 r=4 fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(4, w), fillPaint);
        // circle瞳孔 cx=12 cy=12 r=1.5 dark fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(1.5, w), Paint()..color = const Color(0xFF0A0C1A)..style = PaintingStyle.fill);

      // ============ circle: circle外圈STROKE + circle内点填充 ============
      case 'circle':
        // 外圈 cx=12 cy=12 r=8 stroke
        strokePaint.strokeWidth = sw(2, w);
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(8, w), strokePaint);
        // 内点 cx=12 cy=12 r=3 fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(3, w), fillPaint);

      // ============ book: path两页打开的书STROKE + 中线 ============
      case 'book':
        // 左页: M2 4h6a2 2 0 0 1 2 2v14a1 1 0 0 0-1-1H2V4z stroke
        strokePaint.strokeWidth = sw(1.5, w);
        final leftPage = Path()
          ..moveTo(sx(2, w), sy(4, h))
          ..lineTo(sx(8, w), sy(4, h))
          ..cubicTo(sx(9.1, w), sy(4, h), sx(10, w), sy(4.9, h), sx(10, w), sy(6, h))
          ..lineTo(sx(10, w), sy(20, h))
          ..cubicTo(sx(9.55, w), sy(19.68, h), sx(9.05, w), sy(19, h), sx(8, w), sy(19, h))
          ..lineTo(sx(2, w), sy(19, h))
          ..close();
        canvas.drawPath(leftPage, strokePaint);
        // 右页: M22 4h-6a2 2 0 0 0-2 2v14a1 1 0 0 1 1-1h7V4z stroke
        final rightPage = Path()
          ..moveTo(sx(22, w), sy(4, h))
          ..lineTo(sx(16, w), sy(4, h))
          ..cubicTo(sx(14.9, w), sy(4, h), sx(14, w), sy(4.9, h), sx(14, w), sy(6, h))
          ..lineTo(sx(14, w), sy(20, h))
          ..cubicTo(sx(14.45, w), sy(19.68, h), sx(14.95, w), sy(19, h), sx(16, w), sy(19, h))
          ..lineTo(sx(22, w), sy(19, h))
          ..close();
        canvas.drawPath(rightPage, strokePaint);
        // 中线 x1=12 y1=6 x2=12 y2=20
        strokePaint.strokeWidth = sw(1, w);
        canvas.drawLine(Offset(sx(12, w), sy(6, h)), Offset(sx(12, w), sy(20, h)), strokePaint);

      // ============ scroll: path左右卷边 + rect中间 + line文字线 ============
      case 'scroll':
        // 左卷边: M4 5C4 5 6 3 6 5V19C6 21 4 19 4 19 stroke
        strokePaint.strokeWidth = sw(1.5, w);
        final leftScroll = Path()
          ..moveTo(sx(4, w), sy(5, h))
          ..cubicTo(sx(4, w), sy(5, h), sx(6, w), sy(3, h), sx(6, w), sy(5, h))
          ..lineTo(sx(6, w), sy(19, h))
          ..cubicTo(sx(6, w), sy(21, h), sx(4, w), sy(19, h), sx(4, w), sy(19, h));
        canvas.drawPath(leftScroll, strokePaint);
        // 右卷边: M20 5C20 5 18 3 18 5V19C18 21 20 19 20 19 stroke
        final rightScroll = Path()
          ..moveTo(sx(20, w), sy(5, h))
          ..cubicTo(sx(20, w), sy(5, h), sx(18, w), sy(3, h), sx(18, w), sy(5, h))
          ..lineTo(sx(18, w), sy(19, h))
          ..cubicTo(sx(18, w), sy(21, h), sx(20, w), sy(19, h), sx(20, w), sy(19, h));
        canvas.drawPath(rightScroll, strokePaint);
        // 中间rect x=6 y=5 width=12 height=14 stroke opacity=0.3
        canvas.drawRect(
          Rect.fromLTWH(sx(6, w), sy(5, h), sw(12, w), sh(14, h)),
          Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = sw(1, w),
        );
        // 文字线1: x1=8 y1=9 x2=16 y2=9 opacity=0.6
        strokePaint.strokeWidth = sw(1, w);
        canvas.drawLine(Offset(sx(8, w), sy(9, h)), Offset(sx(16, w), sy(9, h)), Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = sw(1, w));
        // 文字线2: x1=8 y1=12 x2=16 y2=12
        canvas.drawLine(Offset(sx(8, w), sy(12, h)), Offset(sx(16, w), sy(12, h)), Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = sw(1, w));
        // 文字线3: x1=8 y1=15 x2=14 y2=15
        canvas.drawLine(Offset(sx(8, w), sy(15, h)), Offset(sx(14, w), sy(15, h)), Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = sw(1, w));

      // ============ compass: circle外圈 + polygon上下指针 + circle中心 ============
      case 'compass':
        // circle cx=12 cy=12 r=9 stroke
        strokePaint.strokeWidth = sw(1.5, w);
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(9, w), strokePaint);
        // 上指针: points="12,4 14,11 12,10 10,11" fill opacity=0.8
        final northPtr = Path()
          ..moveTo(sx(12, w), sy(4, h))
          ..lineTo(sx(14, w), sy(11, h))
          ..lineTo(sx(12, w), sy(10, h))
          ..lineTo(sx(10, w), sy(11, h))
          ..close();
        canvas.drawPath(northPtr, Paint()..color = color.withOpacity(0.8)..style = PaintingStyle.fill);
        // 下指针: points="12,20 10,13 12,14 14,13" fill opacity=0.4
        final southPtr = Path()
          ..moveTo(sx(12, w), sy(20, h))
          ..lineTo(sx(10, w), sy(13, h))
          ..lineTo(sx(12, w), sy(14, h))
          ..lineTo(sx(14, w), sy(13, h))
          ..close();
        canvas.drawPath(southPtr, Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.fill);
        // 中心点 cx=12 cy=12 r=1 fill
        canvas.drawCircle(Offset(sx(12, w), sy(12, h)), sr(1, w), fillPaint);

      // ============ default: 默认渐变圆点 ============
      default:
        final cx = sx(12, w), cy = sy(12, h);
        final r = sr(8, w);
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
        canvas.drawRect(rect, Paint()
          ..shader = SweepGradient(colors: [
            Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
            Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF),
            Color(0xFF9D4EDD), Color(0xFFFF4D6D),
          ]).createShader(rect));
        // Default from web: book-like shape
        strokePaint.strokeWidth = sw(1.5, w);
        final defaultPath1 = Path()
          ..moveTo(sx(4, w), sy(19.5, h))
          ..cubicTo(sx(4, w), sy(18.12, h), sx(5.12, w), sy(17, h), sx(6.5, w), sy(17, h))
          ..lineTo(sx(20, w), sy(17, h));
        canvas.drawPath(defaultPath1, strokePaint);
        final defaultPath2 = Path()
          ..moveTo(sx(6.5, w), sy(2, h))
          ..lineTo(sx(20, w), sy(2, h))
          ..lineTo(sx(20, w), sy(22, h))
          ..lineTo(sx(6.5, w), sy(22, h))
          ..cubicTo(sx(5.12, w), sy(22, h), sx(4, w), sy(20.88, h), sx(4, w), sy(19.5, h))
          ..lineTo(sx(4, w), sy(4.5, h))
          ..cubicTo(sx(4, w), sy(3.12, h), sx(5.12, w), sy(2, h), sx(6.5, w), sy(2, h))
          ..close();
        canvas.drawPath(defaultPath2, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReligionIconPainter old) =>
      shape != old.shape || color != old.color;
}
