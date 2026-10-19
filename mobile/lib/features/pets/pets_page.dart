import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/gisam_economy.dart';

class PetsPage extends StatefulWidget {
  final GisamEconomy economy;

  const PetsPage({super.key, required this.economy});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  static const _catFrames = [
    'assets/themes/pets/mascotas/gato/quieto.png',
    'assets/themes/pets/mascotas/gato/mirada_l.png',
    'assets/themes/pets/mascotas/gato/lat.png',
  ];
  Timer? _animationTimer;
  int _frameIndex = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _frameIndex = (_frameIndex + 1) % _catFrames.length);
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _adopt(GisamPetOption pet) async {
    setState(() => _busy = true);
    try {
      final success = await widget.economy.adoptPet(pet);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${pet.name} ya es parte de tu familia.'
                : 'Te faltan monedas. Gana más jugando.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la mascota: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hidePet() async {
    try {
      await widget.economy.selectPet(null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el cambio: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.economy,
    builder: (context, _) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mascotas')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Image.asset(
                    _catFrames[_frameIndex],
                    height: 200,
                    cacheHeight: 400,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.pets,
                      size: 120,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compañeros GISAM',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text(
                    'Adopta una mascota y encuéntrala en tu espacio de inicio.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...GisamEconomy.pets.map((pet) {
            final owned = widget.economy.ownedPets.contains(pet.id);
            final selected = widget.economy.activePet == pet.id;
            return Card(
              child: ListTile(
                leading: Image.asset(
                  pet.sprite,
                  width: 54,
                  height: 54,
                  cacheWidth: 108,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.pets),
                ),
                title: Text(pet.name),
                subtitle: Text(
                  selected ? 'Tu compañera' : owned ? 'Adoptada' : 'Primera adopción gratis',
                ),
                trailing: FilledButton.tonal(
                  onPressed: _busy || selected ? null : () => _adopt(pet),
                  child: Text(selected ? 'Activa' : owned ? 'Elegir' : 'Adoptar'),
                ),
              ),
            );
          }),
          if (widget.economy.activePet != null)
            TextButton.icon(
              onPressed: _busy ? null : _hidePet,
              icon: const Icon(Icons.close),
              label: const Text('Ocultar mascota en Inicio'),
            ),
          const SizedBox(height: 10),
          Text(
            'Monedas disponibles: ${widget.economy.coins} 🪙',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    },
  );
}
