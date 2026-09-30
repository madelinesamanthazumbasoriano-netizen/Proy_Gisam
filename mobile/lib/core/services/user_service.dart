import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    String? userId = prefs.getString('user_id');

    if (userId == null || userId.isEmpty) {
      userId = 'usuario_demo';
      await prefs.setString('user_id', userId);
    }

    return userId;
  }

  Future<Map<String, dynamic>> profile(String userId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/users/$userId/profile'),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> missions(String userId) async {
    final r = await http.get(
      Uri.parse('$baseUrl/users/$userId/missions'),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeMission(
    String userId,
    int id,
  ) async {
    final r = await http.post(
      Uri.parse('$baseUrl/users/$userId/missions/$id/complete'),
    );
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<String> createInvite(String userId) async {
    final r = await http.post(
      Uri.parse('$baseUrl/friends/invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    return (jsonDecode(r.body) as Map<String, dynamic>)['token'] as String;
  }

  Future<void> acceptInvite(
    String userId,
    String token,
  ) async {
    await http.post(
      Uri.parse('$baseUrl/friends/invite/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'token': token,
      }),
    );
  }
}
