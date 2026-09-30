import 'package:flutter/material.dart';
import '../../core/gisam_controller.dart';

class FriendsPage extends StatefulWidget {
  final GisamController controller;
  const FriendsPage({super.key, required this.controller});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _friendId = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _friendId.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final friendId = _friendId.text.trim();
    if (friendId.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.controller.addFriend(friendId);
      _friendId.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amigo agregado correctamente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fue posible agregar al amigo. Revisa la conexión y el identificador.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.controller.friends;
    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      body: RefreshIndicator(
        onRefresh: widget.controller.refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Conecta con otra persona mediante su identificador de GISAM.'),
            const SizedBox(height: 16),
            TextField(
              controller: _friendId,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addFriend(),
              decoration: const InputDecoration(
                labelText: 'Identificador de amigo',
                prefixIcon: Icon(Icons.person_add_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _submitting ? null : _addFriend,
              icon: const Icon(Icons.person_add),
              label: Text(_submitting ? 'Agregando...' : 'Agregar amigo'),
            ),
            const SizedBox(height: 24),
            Text('Tus amigos (${friends.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (friends.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.people_outline),
                  title: Text('Aún no tienes amigos agregados'),
                  subtitle: Text('Cuando agregues a alguien aparecerá aquí.'),
                ),
              ),
            ...friends.map((friend) {
              final item = friend as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(item['id']?.toString() ?? 'Usuario GISAM'),
                  subtitle: item['created_at'] == null
                      ? null
                      : Text('Agregado: ${item['created_at']}'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
