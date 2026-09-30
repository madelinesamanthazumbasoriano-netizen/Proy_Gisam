import 'dart:async';
import '../../services/chat_service.dart';

class ChatController {
  final GisamChatService service;
  StreamSubscription<Map<String,dynamic>>? _subscription;
  final messages = <Map<String,dynamic>>[];

  ChatController(this.service);
  void start(void Function(Map<String,dynamic>) onMessage) {
    _subscription = service.connect().listen((message) {
      messages.add(message); onMessage(message);
    });
  }
  void send(String text) {
    if (text.trim().isEmpty) return;
    service.send(text.trim());
  }
  Future<void> dispose() async { await _subscription?.cancel(); await service.close(); }
}
