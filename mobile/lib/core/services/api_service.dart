import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const _requestTimeout = Duration(seconds: 20);
  static const _chatTimeout = Duration(seconds: 90);
  // Android emulator -> 10.0.2.2
  // Teléfono físico -> IP LAN del PC que ejecuta FastAPI.
  static const String baseUrl = String.fromEnvironment(
    'GISAM_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  Future<Map<String, dynamic>> getProfile(String userId) async {
    final r = await http
        .get(Uri.parse('$baseUrl/profile/$userId'))
        .timeout(_requestTimeout);
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(
      String userId, String message) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'message': message}),
        )
        .timeout(_chatTimeout);
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeMission(
      String userId, String missionId) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/missions/complete'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'mission_id': missionId}),
        )
        .timeout(_requestTimeout);
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> linkFriend(String userId, String friendId) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/friends/link'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'friend_id': friendId}),
        )
        .timeout(_requestTimeout);
    _check(r);
  }

  Future<List<dynamic>> getFriends(String userId) async {
    final r = await http
        .get(Uri.parse('$baseUrl/friends/$userId'))
        .timeout(_requestTimeout);
    _check(r);
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return (data['friends'] as List<dynamic>? ?? []);
  }

  Future<Map<String, dynamic>> getHealth() async {
    final r =
        await http.get(Uri.parse('$baseUrl/health')).timeout(_requestTimeout);
    _check(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> sendFeedback(String userId, bool useful) async {
    final r = await http
        .post(
          Uri.parse('$baseUrl/feedback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId, 'useful': useful}),
        )
        .timeout(_requestTimeout);
    _check(r);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GISAM API ${response.statusCode}: ${response.body}');
    }
  }
}
