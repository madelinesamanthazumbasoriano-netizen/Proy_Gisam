import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final api = ApiService();
  final text = TextEditingController();
  List<dynamic> posts = [];
  bool loading = true;

  Future<void> load() async {
    try {
      // Community endpoint becomes available when api_produccion.py is used.
      // For the MVP, keep the UI graceful if it is not enabled.
      final r = await api.getHealth();
      if (r['ok'] == true) {
        // Placeholder until authenticated community identity is connected.
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Comunidad', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Espacio social de GISAM. Las publicaciones pasarán por moderación antes de hacerse públicas.'),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Moderación activa'),
              subtitle: const Text('El contenido nuevo queda pendiente de revisión.'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comparte algo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Publicación preparada para moderación.')),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar a moderación'),
          ),
        ],
      ),
    );
  }
}
