import 'dart:convert';

import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class SpotifyPlaylist {
  final String id;
  final String name;
  final String? imageUrl;
  final String? spotifyUrl;

  const SpotifyPlaylist({
    required this.id,
    required this.name,
    this.imageUrl,
    this.spotifyUrl,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    final firstImage =
        images.isEmpty ? null : images.first as Map<String, dynamic>;
    final externalUrls = json['external_urls'] as Map<String, dynamic>?;
    return SpotifyPlaylist(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Playlist de Spotify',
      imageUrl: firstImage?['url'] as String?,
      spotifyUrl: externalUrls?['spotify'] as String?,
    );
  }
}

class SpotifyService {
  static const _clientId = String.fromEnvironment('SPOTIFY_CLIENT_ID');
  static const redirectUri = String.fromEnvironment(
    'SPOTIFY_REDIRECT_URI',
    defaultValue: 'com.example.gisam_app://oauth',
  );
  static const _appAuth = FlutterAppAuth();

  String? _accessToken;

  bool get isConfigured => _clientId.isNotEmpty;

  Future<void> connect() async {
    if (!isConfigured) {
      throw StateError(
        'Falta SPOTIFY_CLIENT_ID. Revisa mobile/README.md para configurar OAuth.',
      );
    }
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        redirectUri,
        serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: 'https://accounts.spotify.com/authorize',
          tokenEndpoint: 'https://accounts.spotify.com/api/token',
        ),
        scopes: const [
          'playlist-read-private',
          'playlist-read-collaborative',
          'user-library-read',
        ],
        additionalParameters: const {'show_dialog': 'true'},
      ),
    );
    _accessToken = result.accessToken;
    if (_accessToken == null) {
      throw StateError('Spotify no devolvió un token de acceso.');
    }
  }

  Future<List<SpotifyPlaylist>> loadMyPlaylists() async {
    final token = _accessToken;
    if (token == null) {
      throw StateError('Conecta tu cuenta de Spotify para ver tus playlists.');
    }
    final response = await http.get(
      Uri.https('api.spotify.com', '/v1/me/playlists', {'limit': '50'}),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Spotify respondió ${response.statusCode}: ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(SpotifyPlaylist.fromJson)
        .toList(growable: false);
  }

  Future<void> openPlaylist(SpotifyPlaylist playlist) async {
    final url = playlist.spotifyUrl;
    if (url == null || !await launchUrl(Uri.parse(url))) {
      throw StateError('No se pudo abrir la playlist en Spotify.');
    }
  }

  void disconnect() => _accessToken = null;
}
