import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/gisam_controller.dart';

class MusicPage extends StatefulWidget {
  final GisamController controller;

  const MusicPage({super.key, required this.controller});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  static const _sessions = [
    ('Respirar y pausar', '5 min · sonidos ambientales'),
    ('Concentración suave', '15 min · sin letra'),
    ('Descanso nocturno', '20 min · ambiente tranquilo'),
  ];

  Timer? _timer;
  int _selected = 0;
  int _elapsedSeconds = 0;
  bool _playing = false;
  bool _missionRecorded = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleSession() async {
    setState(() => _playing = !_playing);
    if (!_playing) {
      _timer?.cancel();
      return;
    }
    if (!_missionRecorded) {
      _missionRecorded = true;
      try {
        await widget.controller.completeMission('music');
      } catch (_) {
        // La sesión local sigue funcionando aunque la API no esté disponible.
      }
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _playing) setState(() => _elapsedSeconds++);
    });
  }

  String get _elapsedLabel {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Música',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Elige una sesión de bienestar y controla tu tiempo de escucha.'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.graphic_eq, size: 64),
                    const SizedBox(height: 12),
                    Text(_sessions[_selected].$1,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(_sessions[_selected].$2),
                    const SizedBox(height: 18),
                    Text(_elapsedLabel,
                        style: const TextStyle(
                            fontSize: 34,
                            fontFeatures: [FontFeature.tabularFigures()])),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _toggleSession,
                      icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      label:
                          Text(_playing ? 'Pausar sesión' : 'Iniciar sesión'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sesiones disponibles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List.generate(_sessions.length, (index) {
              final session = _sessions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(index == _selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  title: Text(session.$1),
                  subtitle: Text(session.$2),
                  onTap: () => setState(() {
                    _selected = index;
                    _elapsedSeconds = 0;
                    _playing = false;
                    _timer?.cancel();
                  }),
                ),
              );
            }),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Audio personalizable'),
                subtitle: Text(
                    'Añade las pistas autorizadas en assets/music y conecta un proveedor OAuth cuando tengas sus credenciales.'),
              ),
            ),
          ],
        ),
      );
}
