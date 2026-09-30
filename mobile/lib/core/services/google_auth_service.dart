import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final String baseUrl;
  final GoogleSignIn _google;
  GoogleAuthService({
    required this.baseUrl,
    String? serverClientId,
  }) : _google = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: serverClientId,
  );

  Future<Map<String,dynamic>> signIn() async {
    final account = await _google.signIn();
    if (account == null) throw Exception('Inicio de sesión cancelado');
    final auth = await account.authentication;
    final token = auth.idToken;
    if (token == null) throw Exception('Google no devolvió ID token');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google/token'),
      headers: {'Content-Type':'application/json'},
      body: jsonEncode({'id_token': token}),
    );
    if (response.statusCode >= 300) {
      throw Exception('No se pudo autenticar con Google');
    }
    return jsonDecode(response.body) as Map<String,dynamic>;
  }

  Future<void> signOut() => _google.signOut();
}
