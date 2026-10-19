import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpiritTree extends StatefulWidget {
  const SpiritTree({super.key});

  @override
  State<SpiritTree> createState() => _SpiritTreeState();
}

class _SpiritTreeState extends State<SpiritTree>
    with SingleTickerProviderStateMixin {
  static const _encouragements = [
    'Cada pequeño paso también te acerca a donde quieres estar.',
    'Respira: estás haciendo lo mejor que puedes, y eso es suficiente.',
    'Tu crecimiento no tiene que ser rápido para ser valioso.',
    'Date tiempo. Las cosas bonitas también florecen poco a poco.',
    'Confía en ti: ya has superado mucho para llegar hasta aquí.',
  ];

  late final AnimationController _petalAnimation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();
  var _encouragementIndex = -1;

  @override
  void dispose() {
    _petalAnimation.dispose();
    super.dispose();
  }

  void _showEncouragement() {
    setState(() {
      _encouragementIndex =
          (_encouragementIndex + 1) % _encouragements.length;
    });
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.favorite, color: Color(0xFFD9799D)),
        title: const Text('Un mensaje para ti'),
        content: Text(_encouragements[_encouragementIndex]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Gracias'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Árbol de GISAM',
      hint: 'Toca para recibir una frase de aliento',
      child: SizedBox.square(
        dimension: 238,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showEncouragement,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/themes/inicio/Arbol.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFFFE9D8),
                      child: Icon(
                        Icons.park,
                        size: 72,
                        color: Color(0xFF78A888),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _FallingPetalsPainter(_petalAnimation),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallingPetalsPainter extends CustomPainter {
  _FallingPetalsPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _petals = [
    (0.22, 0.03, Color(0xFFF3AFC4)),
    (0.43, 0.19, Color(0xFFFFE4E8)),
    (0.72, 0.36, Color(0xFFE58BAE)),
    (0.32, 0.55, Color(0xFFFFD1E0)),
    (0.81, 0.73, Color(0xFFF3AFC4)),
    (0.57, 0.91, Color(0xFFFFE4E8)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < _petals.length; index++) {
      final (startX, offset, color) = _petals[index];
      final progress = (animation.value + offset) % 1;
      final x = (startX + math.sin(progress * math.pi * 2 + index) * 0.025) *
          size.width;
      final y = (progress * 1.15 - 0.08) * size.height;
      final rotation = progress * math.pi * 2 + index * 0.8;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(4.5, -3.5, 8, 0)
        ..quadraticBezierTo(4.5, 3.5, 0, 0)
        ..close();
      canvas.drawPath(petal, Paint()..color = color.withValues(alpha: 0.9));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingPetalsPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
