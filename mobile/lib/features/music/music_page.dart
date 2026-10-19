import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/gisam_asset_icon.dart';
import '../../core/gisam_controller.dart';
import '../../core/services/spotify_service.dart';

class MusicPage extends StatefulWidget {
  final GisamController controller;
  final String? accountId;

  const MusicPage({
    super.key,
    required this.controller,
    required this.accountId,
  });

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  static const _sessions = [
    ('Respirar y pausar', '5 min · sonidos ambientales'),
    ('Concentración suave', '15 min · sin letra'),
    ('Descanso nocturno', '20 min · ambiente tranquilo'),
  ];

  final _spotify = SpotifyService();
  Timer? _timer;
  int _selected = 0;
  int _elapsedSeconds = 0;
  bool _playing = false;
  bool _missionRecorded = false;
  bool _spotifyLoading = false;
  List<SpotifyPlaylist> _playlists = [];
  String? _spotifyError;

  @override
  void dispose() {
    _timer?.cancel();
    _spotify.disconnect();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MusicPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      _spotify.disconnect();
      _playlists = [];
      _spotifyError = null;
    }
  }

  Future<void> _toggleSession() async {
    if (_playing) {
      setState(() => _playing = false);
      _timer?.cancel();
      return;
    }
    setState(() => _playing = true);
    if (!_missionRecorded) {
      try {
        await widget.controller.completeMission('music');
        _missionRecorded = true;
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se registró la misión: $error')),
          );
        }
      }
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _playing) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _connectSpotify() async {
    setState(() {
      _spotifyLoading = true;
      _spotifyError = null;
    });
    try {
      await _spotify.connect();
      final playlists = await _spotify.loadMyPlaylists();
      if (mounted) setState(() => _playlists = playlists);
    } catch (error) {
      if (mounted) setState(() => _spotifyError = error.toString());
    } finally {
      if (mounted) setState(() => _spotifyLoading = false);
    }
  }

  Future<void> _openPlaylist(SpotifyPlaylist playlist) async {
    try {
      await _spotify.openPlaylist(playlist);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir Spotify: $error')),
        );
      }
    }
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
            const Text(
              'Música',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tus playlists de Spotify se muestran desde la cuenta conectada.',
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const GisamAssetIcon(
                      assetPath: 'assets/themes/musica/Spotify.jpg',
                      size: 36,
                    ),
                    title: const Text('Tu catálogo de Spotify'),
                    subtitle: Text(
                      widget.accountId == null
                          ? 'Cada persona conecta su propia cuenta Spotify.'
                          : 'Cuenta GISAM vinculada · catálogo de Spotify personal.',
                    ),
                    trailing: _spotifyLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: 'Conectar Spotify',
                            onPressed: _connectSpotify,
                            icon: const Icon(Icons.link),
                          ),
                  ),
                  if (_spotifyError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        _spotifyError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_playlists.isNotEmpty)
                    ..._playlists.map(
                      (playlist) => ListTile(
                        leading: playlist.imageUrl == null
                            ? const Icon(Icons.queue_music)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  playlist.imageUrl!,
                                  width: 44,
                                  height: 44,
                                  cacheWidth: 88,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.queue_music),
                                ),
                              ),
                        title: Text(
                          playlist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _openPlaylist(playlist),
                      ),
                    ),
                  if (_playlists.isEmpty && _spotifyError == null)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Conecta Spotify para cargar tus playlists personales.',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Temporizador de bienestar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.graphic_eq, size: 54),
                    const SizedBox(height: 12),
                    Text(
                      _sessions[_selected].$1,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_sessions[_selected].$2),
                    const SizedBox(height: 18),
                    Text(
                      _elapsedLabel,
                      style: const TextStyle(
                        fontSize: 34,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _toggleSession,
                      icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                      label: Text(
                        _playing ? 'Pausar sesión' : 'Iniciar sesión',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sesiones disponibles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(_sessions.length, (index) {
              final session = _sessions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    index == _selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
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
          ],
        ),
      );
}
