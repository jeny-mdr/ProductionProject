import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  String? get token          => _token;
  Map<String, dynamic>? get user => _user;
  bool   get isLoading       => _isLoading;
  String? get error          => _error;
  bool   get isAuthenticated => _token != null;
  bool   get isDoctor        => _user?['role'] == 'doctor';

  Future<void> loadToken() async {
    _token = await _storage.read(
        key: 'access_token');
    notifyListeners();
  }

  Future<bool> login(
      String username, String password) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse(kLoginUrl),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access'];
        await _storage.write(
            key: 'access_token',
            value: data['access']);
        await _storage.write(
            key: 'refresh_token',
            value: data['refresh']);
        await fetchProfile();
        _setLoading(false);
        return true;
      }
      _error = _parseError(res.body);
      _setLoading(false);
      return false;
    } catch (_) {
      _error =
      'Cannot reach server.\nCheck your IP in constants.dart';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
      Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      final res = await http.post(
        Uri.parse(kRegisterUrl),
        headers: {
          'Content-Type': 'application/json'
        },
        body: jsonEncode(payload),
      );
      if (res.statusCode == 201) {
        _setLoading(false);
        return true;
      }
      _error = _parseError(res.body);
      _setLoading(false);
      return false;
    } catch (_) {
      _error =
      'Cannot reach server.\nCheck your IP in constants.dart';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse(kProfileUrl),
        headers: {
          'Authorization': 'Bearer $_token'
        },
      );
      if (res.statusCode == 200) {
        _user = jsonDecode(res.body);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _token = null;
    _user  = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _parseError(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map) {
        final first = m.values.first;
        if (first is List) {
          return first.first.toString();
        }
        return first.toString();
      }
    } catch (_) {}
    return 'Something went wrong.';
  }
}