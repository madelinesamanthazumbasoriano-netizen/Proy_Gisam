import 'package:flutter/material.dart';
import '../../core/gisam_controller.dart';

class ProfilePage extends StatefulWidget {
  final GisamController controller;
  const ProfilePage({super.key, required this.controller});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.progress;
    final userId = widget.controller.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('👤 Perfil')),
      body: RefreshIndicator(
        onRefresh: widget.controller.refreshProfile,
        child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(radius: 42, child: Text(userId.isEmpty ? 'G' : userId[0].toUpperCase())),
                const SizedBox(height: 12),
                Center(child: Text(userId.isEmpty ? 'Usuario GISAM' : userId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                const SizedBox(height: 4),
                const Center(child: Text('Tu progreso se sincroniza con GISAM')),
                const SizedBox(height: 20),
                Card(child: ListTile(title: const Text('Nivel'), trailing: Text('${progress.level}'))),
                Card(child: ListTile(title: const Text('XP'), trailing: Text('${progress.xp} / ${progress.xpRequired}'))),
                Card(child: ListTile(title: const Text('💧 Agua'), trailing: Text('${progress.water}%'))),
                Card(child: ListTile(title: const Text('❤️ Salud del árbol'), trailing: Text('${progress.health}%'))),
                Card(child: ListTile(title: const Text('😊 Felicidad'), trailing: Text('${progress.happiness}%'))),
              ],
            ),
      ),
    );
  }
}
