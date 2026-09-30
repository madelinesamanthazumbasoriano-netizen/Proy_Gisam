import 'package:flutter/material.dart';
import '../../core/services/user_service.dart';

class MissionsPage extends StatefulWidget {
  final String userId;
  final String baseUrl;
  const MissionsPage({super.key, required this.userId, required this.baseUrl});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  late final UserService api;
  List<dynamic> missions = [];

  @override
  void initState() {
    super.initState();
    api = UserService(baseUrl: widget.baseUrl);
    load();
  }

  Future<void> load() async {
    final result = await api.missions(widget.userId);
    if (mounted) setState(() => missions = result['missions'] ?? []);
  }

  Future<void> complete(int id) async {
    await api.completeMission(widget.userId, id);
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('🎯 Misiones')),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      itemBuilder: (_, i) {
        final m = missions[i] as Map<String, dynamic>;
        final done = m['completed'] == 1;
        return Card(
          child: ListTile(
            leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
            title: Text(m['title']),
            subtitle: Text('+${m['xp_reward']} XP'),
            trailing: done ? const Text('LISTA') : FilledButton(
              onPressed: () => complete(m['id'] as int),
              child: const Text('Completar'),
            ),
          ),
        );
      },
    ),
  );
}
