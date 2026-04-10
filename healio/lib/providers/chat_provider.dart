import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

class ChatMessage {
  final String sender;
  final String message;
  final DateTime timestamp;
  final bool isMe;

  const ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isMe,
  });
}

class ChatProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  final List<ChatMessage> _messages = [];
  String? _myUsername;
  bool _isConnected  = false;
  bool _isConnecting = false;

  List<ChatMessage> get messages =>
      List.unmodifiable(_messages);
  bool get isConnected  => _isConnected;
  bool get isConnecting => _isConnecting;

  void connect(
      String otherUserId,
      String token,
      String myUsername,
      ) {
    if (_isConnected) disconnect();
    _myUsername   = myUsername;
    _isConnecting = true;
    _messages.clear();
    notifyListeners();

    _channel = WebSocketChannel.connect(
      Uri.parse(kChatWsUrl(otherUserId, token)),
    );
    _isConnected  = true;
    _isConnecting = false;
    notifyListeners();

    _channel!.stream.listen(
          (raw) {
        final data = jsonDecode(raw as String);
        if (data is Map &&
            data['type'] == 'history') {
          final msgs = data['messages'] as List;
          for (final m in msgs) {
            _addMsg(Map<String, dynamic>.from(m));
          }
        } else if (data is Map &&
            data['type'] == 'message') {
          _addMsg(Map<String, dynamic>.from(data));
        } else if (data is List) {
          for (final m in data) {
            _addMsg(Map<String, dynamic>.from(m));
          }
        }
        notifyListeners();
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('WebSocket error: $e');
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  void _addMsg(dynamic m) {
    final msg = Map<String, dynamic>.from(m);
    _messages.add(ChatMessage(
      sender:    msg['sender']?.toString()  ?? '',
      message:   msg['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(
        msg['timestamp']?.toString() ?? '',
      ) ?? DateTime.now(),
      isMe: msg['sender']?.toString() == _myUsername,
    ));
  }

  void sendMessage(String text) {
    if (_channel == null || !_isConnected) {
      return;
    }
    _channel!.sink
        .add(jsonEncode({'message': text}));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel      = null;
    _isConnected  = false;
    _isConnecting = false;
    _messages.clear();
  }
}