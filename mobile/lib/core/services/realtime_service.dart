import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeService {
  WebSocketChannel? _channel;

  Stream<dynamic> connect(String baseHttpUrl) {
    final uri = Uri.parse(
        '${baseHttpUrl.replaceFirst(RegExp(r'^http'), 'ws')}/ws/chat');
    _channel = WebSocketChannel.connect(uri);
    return _channel!.stream;
  }

  void send({required String userId, required String message}) {
    _channel?.sink.add(jsonEncode({'user_id': userId, 'message': message}));
  }

  Future<void> close() async => _channel?.sink.close();
}
