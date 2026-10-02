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
          filterQuality: FilterQuality.high,
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
          colorBlendMode: BlendMode.darken,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF6D7E8), Color(0xFFEDEBFF)],
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
