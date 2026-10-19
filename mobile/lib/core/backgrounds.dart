import 'package:flutter/material.dart';

class GisamBackgroundOption {
  final String label;
  final String assetPath;
  final int price;

  const GisamBackgroundOption({
    required this.label,
    required this.assetPath,
    required this.price,
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
      price: 0,
    ),
    GisamBackgroundOption(
      label: 'Cielo rosado',
      assetPath: 'assets/themes/theme 2.jpg',
      price: 80,
    ),
    GisamBackgroundOption(
      label: 'Té y sakura',
      assetPath: 'assets/themes/theme 3.jpg',
      price: 100,
    ),
    GisamBackgroundOption(
      label: 'Jardín rosa',
      assetPath: 'assets/themes/theme 4.jpg',
      price: 120,
    ),
    GisamBackgroundOption(
      label: 'Jardín verde',
      assetPath: 'assets/themes/theme 5.jpg',
      price: 150,
    ),
    GisamBackgroundOption(
      label: 'Atardecer mágico',
      assetPath: 'assets/themes/theme 6.jpg',
      price: 180,
    ),
    GisamBackgroundOption(
      label: 'Zen minimalista',
      assetPath: 'assets/themes/Theme 7.jpg',
      price: 220,
    ),
    GisamBackgroundOption(
      label: 'Sakura suave',
      assetPath: 'assets/themes/Theme 8.jpg',
      price: 250,
    ),
  ];

  static const String defaultAssetPath = 'assets/themes/theme 1.jpg';

  static String normalize(String? assetPath) {
    final candidate = assetPath?.trim() ?? '';
    if (candidate.isEmpty) {
      return defaultAssetPath;
    }

    final normalized = candidate.replaceAll(RegExp(r'\s+'), ' ');
    for (final option in options) {
      final optionPath = option.assetPath.trim();
      if (optionPath.toLowerCase() == normalized.toLowerCase()) {
        return option.assetPath;
      }
    }

    return defaultAssetPath;
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
    final safeAsset = GisamBackgrounds.normalize(assetPath);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          safeAsset,
          fit: BoxFit.cover,
          cacheWidth: 1280,
          filterQuality: FilterQuality.medium,
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(0, 246, 215, 232),
                  Color.fromARGB(0, 237, 235, 255)
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark
                      ? Colors.black.withValues(alpha: 0.36)
                      : Colors.white.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
