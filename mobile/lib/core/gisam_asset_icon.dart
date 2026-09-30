import 'package:flutter/material.dart';

class GisamAssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool selected;
  final double borderRadius;

  const GisamAssetIcon({
    super.key,
    required this.assetPath,
    this.size = 28,
    this.selected = false,
    this.borderRadius = 9,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: EdgeInsets.all(selected ? 1.5 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.22),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.75,
          ),
        ),
      ),
    );
  }
}
