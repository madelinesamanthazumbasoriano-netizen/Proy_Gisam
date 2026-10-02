import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpiritTree extends StatefulWidget {
  const SpiritTree({super.key});

  @override
  State<SpiritTree> createState() => _SpiritTreeState();
}

class _SpiritTreeState extends State<SpiritTree>
    with SingleTickerProviderStateMixin {
  late final AnimationController _leafAnimation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _leafAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Árbol espiritual de GISAM con pétalos cayendo',
      child: SizedBox.square(
        dimension: 238,
        child: RepaintBoundary(
          child: CustomPaint(painter: _SpiritTreePainter(_leafAnimation)),
        ),
      ),
    );
  }
}

class _SpiritTreePainter extends CustomPainter {
  _SpiritTreePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _leafColors = [
    Color(0xFF78A888),
    Color(0xFF93B99A),
    Color(0xFFE995B7),
    Color(0xFFF4B5C8),
    Color(0xFFE7A76E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const sceneSize = 240.0;
    final scale = math.min(size.width / sceneSize, size.height / sceneSize);
    if (scale <= 0) return;

    canvas.save();
    canvas.translate(
      (size.width - sceneSize * scale) / 2,
      (size.height - sceneSize * scale) / 2,
    );
    canvas.scale(scale);

    _paintAura(canvas);
    _paintGround(canvas);
    _paintTrunk(canvas);
    _paintCanopy(canvas);
    _paintPot(canvas);
    _paintFallingPetals(canvas);

    canvas.restore();
  }

  void _paintAura(Canvas canvas) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x2D70B49A), Color(0x12EBA6C0), Color(0x00FFFFFF)],
        stops: [0, 0.62, 1],
      ).createShader(
          Rect.fromCircle(center: const Offset(120, 88), radius: 94));
    canvas.drawCircle(const Offset(120, 88), 94, paint);
  }

  void _paintGround(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 222), width: 128, height: 12),
      Paint()
        ..color = const Color(0x263D5C49)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  void _paintTrunk(Canvas canvas) {
    final trunk = Path()
      ..moveTo(119, 193)
      ..cubicTo(96, 174, 141, 156, 122, 135)
      ..cubicTo(108, 119, 115, 103, 119, 86);
    _drawBranch(canvas, trunk, 17);

    final branches = [
      Path()
        ..moveTo(122, 139)
        ..cubicTo(101, 132, 87, 111, 81, 93)
        ..cubicTo(76, 79, 65, 72, 53, 68),
      Path()
        ..moveTo(118, 122)
        ..cubicTo(142, 116, 151, 98, 159, 82)
        ..cubicTo(166, 70, 177, 66, 190, 67),
      Path()
        ..moveTo(115, 151)
        ..cubicTo(97, 143, 83, 137, 67, 125),
      Path()
        ..moveTo(126, 145)
        ..cubicTo(144, 138, 160, 128, 174, 115),
    ];
    for (final branch in branches) {
      _drawBranch(canvas, branch, 7);
    }

    final roots = [
      Path()
        ..moveTo(118, 183)
        ..cubicTo(103, 191, 88, 193, 72, 190),
      Path()
        ..moveTo(122, 184)
        ..cubicTo(138, 193, 153, 194, 169, 189),
    ];
    for (final root in roots) {
      _drawBranch(canvas, root, 6);
    }
  }

  void _drawBranch(Canvas canvas, Path path, double width) {
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF765448)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB88467).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, width * 0.22)
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintCanopy(Canvas canvas) {
    const clusters = [
      (67.0, 76.0, 20.0, 15.0, 2),
      (96.0, 57.0, 25.0, 18.0, 5),
      (130.0, 51.0, 24.0, 18.0, 7),
      (163.0, 70.0, 25.0, 18.0, 11),
      (185.0, 91.0, 17.0, 14.0, 13),
      (83.0, 103.0, 25.0, 17.0, 17),
      (122.0, 91.0, 30.0, 19.0, 19),
      (158.0, 106.0, 25.0, 16.0, 23),
    ];

    for (final (x, y, radiusX, radiusY, seed) in clusters) {
      for (var index = 0; index < 28; index++) {
        final angle = 2 * math.pi * ((index * 7 + seed) % 29) / 29;
        final spread = 0.34 + ((index * 11 + seed) % 17) / 25;
        final leafX = x + math.cos(angle) * radiusX * spread;
        final leafY = y + math.sin(angle) * radiusY * spread;
        final color = _leafColors[(index + seed) % _leafColors.length];
        final width = 7.5 + (index % 3) * 1.6;
        final height = 4.0 + (index % 2) * 1.5;

        canvas.save();
        canvas.translate(leafX, leafY);
        canvas.rotate(angle + 0.38);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: width,
            height: height,
          ),
          Paint()..color = color,
        );
        canvas.restore();
      }
    }

    const blossoms = [
      (77.0, 68.0, 1.0),
      (105.0, 47.0, 0.9),
      (136.0, 62.0, 1.1),
      (174.0, 76.0, 0.95),
      (96.0, 99.0, 0.85),
      (133.0, 91.0, 0.9),
      (163.0, 105.0, 0.8),
    ];
    for (final (x, y, blossomScale) in blossoms) {
      _drawBlossom(canvas, Offset(x, y), blossomScale);
    }
  }

  void _drawBlossom(Canvas canvas, Offset center, double scale) {
    for (var petal = 0; petal < 5; petal++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(petal * math.pi * 2 / 5);
      canvas.drawOval(
        Rect.fromLTWH(-2.1 * scale, -7.0 * scale, 4.2 * scale, 6.1 * scale),
        Paint()..color = const Color(0xFFFFD4DF),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      center,
      1.8 * scale,
      Paint()..color = const Color(0xFFE7AC62),
    );
  }

  void _paintPot(Canvas canvas) {
    final pot = Path()
      ..moveTo(63, 190)
      ..quadraticBezierTo(120, 199, 177, 190)
      ..lineTo(166, 218)
      ..quadraticBezierTo(120, 231, 74, 218)
      ..close();
    canvas.drawPath(
      pot,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3B8CA), Color(0xFFD9799D)],
        ).createShader(const Rect.fromLTWH(63, 190, 114, 41)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 191), width: 116, height: 14),
      Paint()..color = const Color(0xFFFFD0DE),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 191), width: 94, height: 8),
      Paint()..color = const Color(0xFF698A63),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(103, 222, 34, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFC8678D),
    );
  }

  void _paintFallingPetals(Canvas canvas) {
    const launchPoints = [
      (57.0, 0.04),
      (92.0, 0.19),
      (145.0, 0.37),
      (188.0, 0.54),
      (74.0, 0.72),
      (168.0, 0.88),
    ];
    const petalColors = [
      Color(0xFFE58BAE),
      Color(0xFFF0B46E),
      Color(0xFF79A98B),
      Color(0xFFF3AFC4),
      Color(0xFFDEA0BC),
      Color(0xFFE3B65F),
    ];

    for (var index = 0; index < launchPoints.length; index++) {
      final (startX, offset) = launchPoints[index];
      final progress = (animation.value + offset) % 1;
      final x = startX + math.sin(progress * math.pi * 2 + index) * 13;
      final y = 35 + progress * 143;
      final rotation = progress * math.pi * 4 + index * 0.9;
      _drawPetal(canvas, Offset(x, y), rotation, petalColors[index]);
    }
  }

  void _drawPetal(Canvas canvas, Offset center, double rotation, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final petal = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(5, -4, 10, 0)
      ..quadraticBezierTo(5, 4, 0, 0)
      ..close();
    canvas.drawPath(petal, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpiritTreePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
