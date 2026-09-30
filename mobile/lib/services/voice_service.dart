import 'dart:convert';
import 'package:http/http.dart' as http;

class GisamVoiceService {
  final String baseUrl;
  final String token;
  GisamVoiceService({required this.baseUrl, required this.token});

  Future<Map<String, dynamic>> transcribeAndChat(List<int> wavBytes) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/voice/transcribe-and-chat'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('audio', wavBytes, filename: 'input.wav'));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 300) throw Exception(body);
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
