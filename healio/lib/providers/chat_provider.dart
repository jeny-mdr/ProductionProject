import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/constants.dart';

class ChatMessage {
  final String  sender;
  final String  message;
  final DateTime timestamp;
  final bool    isMe;
  final String  messageType;
  final String? fileUrl;
  final String? fileName;

  const ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
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

  Future<void> connect(
      String otherUserId,
      String token,
      String myUsername,
      ) async {
    // Prevent double connection
    if (_isConnecting) return;

    // Force close any existing connection
    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel      = null;
    _isConnected  = false;
    _isConnecting = false;
    _messages.clear();
    _myUsername   = myUsername;

    // Wait for old connection to fully close
    await Future.delayed(
        const Duration(milliseconds: 300));

    _isConnecting = true;
    notifyListeners();

    try {
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
    } catch (e) {
      debugPrint('WebSocket connect error: $e');
      _isConnected  = false;
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _addMsg(dynamic m) {
    final msg = Map<String, dynamic>.from(m);
    _messages.add(ChatMessage(
      sender:      msg['sender']?.toString()  ?? '',
      message:     msg['message']?.toString() ?? '',
      timestamp:   DateTime.tryParse(
        msg['timestamp']?.toString() ?? '',
      ) ?? DateTime.now(),
      isMe:        msg['sender']?.toString() == _myUsername,
      messageType: msg['message_type']?.toString() ?? 'text',
      fileUrl:     msg['file_url']?.toString(),
      fileName:    msg['file_name']?.toString(),
    ));
  }

  void addFileMessage({
    required String fileName,
    required String fileUrl,
    required String messageType,
    required String sender,
  }) {
    _messages.add(ChatMessage(
      sender:      sender,
      message:     '📎 $fileName',
      timestamp:   DateTime.now(),
      isMe:        true,
      messageType: messageType,
      fileUrl:     fileUrl,
      fileName:    fileName,
    ));
    notifyListeners();
  }

  void sendMessage(String text) {
    if (_channel == null || !_isConnected) return;
    _channel!.sink.add(jsonEncode({'message': text}));
  }

  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel      = null;
    _isConnected  = false;
    _isConnecting = false;
    _messages.clear();
    notifyListeners();
  }

  void reset() {
    disconnect();
    _myUsername = null;
  }
}