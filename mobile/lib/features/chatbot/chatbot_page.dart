import 'package:flutter/material.dart';
import '../../core/gisam_controller.dart';

class ChatbotPage extends StatefulWidget {
  final GisamController controller;

  const ChatbotPage({super.key, required this.controller});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final controllerText = TextEditingController();
  final messages = <Map<String, dynamic>>[];
  bool loading = false;
  bool canRate = false;

  Future<void> send() async {
    final text = controllerText.text.trim();
    if (text.isEmpty || loading) return;

    setState(() {
      messages.add({'role': 'user', 'text': text});
      controllerText.clear();
      loading = true;
    });

    try {
      final data = await widget.controller.chat(text);
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'gisam',
          'text': data['response'] ?? 'No pude responder.',
          'emotion': data['emotion'],
          'llm': data['llm_used'] == true,
          'model': (data['llm'] as Map<String, dynamic>?)?['model'],
        });
        canRate = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'gisam',
          'text': 'No pude conectar con el motor de GISAM. Revisa el servidor y la URL de la API.',
        });
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> rate(bool useful) async {
    try {
      await widget.controller.api.sendFeedback(widget.controller.userId, useful);
      if (mounted) setState(() => canRate = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('GISAM IA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final user = m['role'] == 'user';
                return Align(
                  alignment: user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 330),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['text'] ?? ''),
                            if (!user && m['emotion'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Señal orientativa: ${m['emotion']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (!user && m['llm'] == true)
                              Text(
                                'Respuesta generada por ${m['model'] ?? 'NVIDIA Nemotron'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (canRate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('¿Te sirvió?'),
                  IconButton(onPressed: () => rate(true), icon: const Icon(Icons.thumb_up_outlined)),
                  IconButton(onPressed: () => rate(false), icon: const Icon(Icons.thumb_down_outlined)),
                ],
              ),
            ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllerText,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      hintText: 'Habla con GISAM...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
