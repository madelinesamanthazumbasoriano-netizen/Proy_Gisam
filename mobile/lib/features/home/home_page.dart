import 'package:flutter/material.dart';
import '../../core/gisam_controller.dart';

class HomePage extends StatelessWidget {
  final GisamController controller;

  const HomePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final p = controller.progress;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('GISAM', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const Text('Tu espacio de bienestar y crecimiento'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/themes/inicio/Arbol.jpg',
                        width: 190,
                        height: 190,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Árbol de GISAM',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StatRow(icon: '💧', label: 'Agua', value: p.water),
                    _StatRow(icon: '❤️', label: 'Salud', value: p.health),
                    _StatRow(icon: '😊', label: 'Felicidad', value: p.happiness),
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
                    Text('Nivel ${p.level}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: p.progress, minHeight: 12),
                    const SizedBox(height: 8),
                    Text('${p.xp} / ${p.xpRequired} XP'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🎯 Misiones', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...controller.missions.map(
              (mission) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    mission.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: mission.completed ? Colors.green : null,
                  ),
                  title: Text(mission.title),
                  subtitle: Text('+${mission.xp} XP'),
                  onTap: mission.completed
                      ? null
                      : () async {
                          await controller.completeMission(mission.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('🎉 ${mission.title} +${mission.xp} XP')),
                            );
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

  const _StatRow({required this.icon, required this.label, required this.value});

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
