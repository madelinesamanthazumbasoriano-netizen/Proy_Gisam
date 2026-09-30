import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class GisamChatService {
  final String wsBaseUrl;
  final String token;
  WebSocketChannel? _channel;

  GisamChatService({required this.wsBaseUrl, required this.token});

  Stream<Map<String, dynamic>> connect() {
    final uri = Uri.parse('$wsBaseUrl/ws/chat?token=${Uri.encodeQueryComponent(token)}');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream.map((event) => jsonDecode(event as String) as Map<String, dynamic>);
  }

  void send(String text) => _channel?.sink.add(jsonEncode({'text': text}));
  Future<void> close() async => _channel?.sink.close();
}
