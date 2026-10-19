import 'package:flutter/material.dart';

import '../../core/backgrounds.dart';
import '../../core/services/gisam_economy.dart';

class StorePage extends StatelessWidget {
  final GisamEconomy economy;
  final VoidCallback onOpenPets;

  const StorePage({
    super.key,
    required this.economy,
    required this.onOpenPets,
  });

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: economy,
    builder: (context, _) {
      final colors = Theme.of(context).colorScheme;
      return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/themes/tienda/tienda.png',
                width: 44,
                height: 44,
                cacheWidth: 88,
                fit: BoxFit.cover,
                semanticLabel: 'Logo de la tienda',
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.storefront, color: colors.primary),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Tienda GISAM'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _CoinPill(coins: economy.coins)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Haz tu espacio más tuyo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          const Text('Gana monedas jugando y desbloquea nuevos fondos.'),
          const SizedBox(height: 18),
          Text(
            'Fondos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          ...GisamBackgrounds.options.map((option) {
            final owned = economy.ownedBackgrounds.contains(option.assetPath);
            final selected = economy.activeBackground == option.assetPath;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    option.assetPath,
                    height: 132,
                    cacheWidth: 720,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 132,
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  ListTile(
                    title: Text(option.label),
                    subtitle: Text(
                      selected
                          ? 'En uso'
                          : owned
                              ? 'Desbloqueado'
                              : '${option.price} monedas',
                    ),
                    trailing: _BackgroundAction(
                      owned: owned,
                      selected: selected,
                      price: option.price,
                      onTap: () async {
                        try {
                          if (owned) {
                            await economy.selectBackground(option.assetPath);
                            _showMessage(context, 'Fondo aplicado.');
                          } else {
                            final bought = await economy.buyBackground(option);
                            _showMessage(
                              context,
                              bought
                                  ? 'Fondo desbloqueado. Ya puedes usarlo.'
                                  : 'Te faltan monedas. ¡Prueba un minijuego!',
                            );
                          }
                        } catch (error) {
                          _showMessage(context, 'No se pudo guardar: $error');
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.pets_outlined),
              title: const Text('Mascotas'),
              subtitle: const Text('Conoce y adopta una mascota compañera.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenPets,
            ),
          ),
        ],
      ),
      );
    },
  );
}

class _BackgroundAction extends StatelessWidget {
  final bool owned;
  final bool selected;
  final int price;
  final VoidCallback onTap;

  const _BackgroundAction({
    required this.owned,
    required this.selected,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return FilledButton.tonal(
      onPressed: onTap,
      child: Text(owned ? 'Usar' : '$price 🪙'),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;

  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            '$coins 🪙',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
}
