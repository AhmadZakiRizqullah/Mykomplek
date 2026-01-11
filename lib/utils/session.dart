import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Session {
  static const String _keyToken = 'token';
  static const String _keyUser = 'user';

  static Future<void> saveSession(
    String token,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final userStr = prefs.getString(_keyUser);

    if (token == null || userStr == null) return null;

    final user = jsonDecode(userStr);
    return {
      'token': token,
      'user': user,
      'id': user['id'],
      'username': user['username'],
      'full_name': user['full_name'],
      'role': user['role'],
    };
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
