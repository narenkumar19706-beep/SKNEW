import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';

class SocketService {
  WebSocket? _socket;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect(String sosId) async {
    final wsUrl = AppConstants.baseUrl.replaceFirst('http', 'ws');
    _socket = await WebSocket.connect('$wsUrl/ws');
    _socket?.add(jsonEncode({'type': 'subscribe', 'sosId': sosId}));
    _socket?.listen(
      (event) {
        try {
          final payload = jsonDecode(event.toString()) as Map<String, dynamic>;
          _controller.add(payload);
        } catch (error) {
          return;
        }
      },
      onDone: () => _controller.add({'type': 'closed'}),
    );
  }

  Future<void> disconnect() async {
    _socket?.add(jsonEncode({'type': 'unsubscribe'}));
    await _socket?.close();
    _socket = null;
  }

  void dispose() {
    _controller.close();
  }
}
