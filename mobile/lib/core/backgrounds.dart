import 'package:flutter/material.dart';

class GisamBackgroundOption {
  final String label;
  final String assetPath;

  const GisamBackgroundOption({
    required this.label,
    required this.assetPath,
  });
}

class GisamBackgrounds {
  /// Los fondos reales que ya existen dentro de assets/themes.
  /// El sistema queda listo para añadir Tema 9 y Tema 10 cuando se
  /// coloquen esos archivos en la carpeta.
  static const List<GisamBackgroundOption> options = [
    GisamBackgroundOption(
      label: 'Sakura nocturna',
      assetPath: 'assets/themes/theme 1.jpg',
    ),
    GisamBackgroundOption(
      label: 'Cielo rosado',
      assetPath: 'assets/themes/theme 2.jpg',
    ),
    GisamBackgroundOption(
      label: 'Té y sakura',
      assetPath: 'assets/themes/theme 3.jpg',
    ),
    GisamBackgroundOption(
      label: 'Jardín rosa',
      assetPath: 'assets/themes/theme 4.jpg',
    ),
    GisamBackgroundOption(
      label: 'Jardín verde',
      assetPath: 'assets/themes/theme 5.jpg',
    ),
    GisamBackgroundOption(
      label: 'Atardecer mágico',
      assetPath: 'assets/themes/theme 6.jpg',
    ),
    GisamBackgroundOption(
      label: 'Zen minimalista',
      assetPath: 'assets/themes/Theme 7.jpg',
    ),
    GisamBackgroundOption(
      label: 'Sakura suave',
      assetPath: 'assets/themes/Theme 8.jpg',
    ),
  ];

  static const String defaultAssetPath = 'assets/themes/theme 1.jpg';

  static String normalize(String? assetPath) {
    return options.any((option) => option.assetPath == assetPath)
        ? assetPath!
        : defaultAssetPath;
  }
}

class GisamBackground extends StatelessWidget {
  final String assetPath;
  final Widget child;

  const GisamBackground({
    super.key,
    required this.assetPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFFF7F8FC),
          ),
        ),
        ColoredBox(
          color: isDark
              ? Colors.black.withValues(alpha: 0.34)
              : Colors.white.withValues(alpha: 0.24),
        ),
        child,
      ],
    );
  }
}
