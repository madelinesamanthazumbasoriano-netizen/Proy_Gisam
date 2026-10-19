import 'package:flutter/material.dart';

import '../../core/gisam_controller.dart';
import '../../core/services/gisam_economy.dart';
import '../pets/pets_page.dart';
import 'spirit_tree.dart';

class HomePage extends StatelessWidget {
  final GisamController controller;
  final GisamEconomy economy;

  const HomePage({super.key, required this.controller, required this.economy});

  @override
  Widget build(BuildContext context) {
    final p = controller.progress;
    final matchingPets =
        GisamEconomy.pets.where((pet) => pet.id == economy.activePet).toList();
    final activePet =
        matchingPets.isEmpty ? GisamEconomy.pets.first : matchingPets.first;
    final hasActivePet = matchingPets.isNotEmpty;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/themes/inicio/Logo-inicia.jpg',
                  width: 58,
                  height: 58,
                  cacheWidth: 116,
                  errorBuilder: (_, __, ___) => const Icon(Icons.spa, size: 48),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GISAM',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Tu espacio de bienestar y crecimiento'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: const SpiritTree(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Árbol de GISAM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1DF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            activePet.sprite,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.pets,
                              size: 40,
                              color: Color(0xFF8A648D),
                            ),
                          ),
                        ),
                        title: Text(
                          hasActivePet
                              ? 'Tu compañera: ${activePet.name}'
                              : 'Conoce a ${activePet.name}',
                        ),
                        subtitle: Text(
                          hasActivePet
                              ? 'Cuida de ella y vuelve a visitarla.'
                              : 'Visita Mascotas para adoptarla gratis.',
                        ),
                        trailing: const Icon(Icons.pets_outlined),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetsPage(economy: economy),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatRow(icon: '💧', label: 'Agua', value: p.water),
                    _StatRow(icon: '❤️', label: 'Salud', value: p.health),
                    _StatRow(
                        icon: '😊', label: 'Felicidad', value: p.happiness),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nivel ${p.level}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: p.progress, minHeight: 12),
                    const SizedBox(height: 8),
                    Text('${p.xp} / ${p.xpRequired} XP'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🎯 Misiones',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...controller.missions.map(
              (mission) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    mission.completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: mission.completed ? Colors.green : null,
                  ),
                  title: Text(mission.title),
                  subtitle: Text('+${mission.xp} XP'),
                  onTap: mission.completed
                      ? null
                      : () async {
                          try {
                            await controller.completeMission(mission.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '¡${mission.title}! +${mission.xp} XP',
                                  ),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('No se completó la misión: $error'),
                                ),
                              );
                            }
                          }
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String icon;
  final String label;
  final int value;

  const _StatRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text('$value%', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
