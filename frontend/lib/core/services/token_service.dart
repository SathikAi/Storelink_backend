import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  final FlutterSecureStorage? _secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  TokenService()
      : _secureStorage = kIsWeb
            ? null
            : const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
                iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              );

  Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, token);
    } else {
      await _secureStorage!.write(key: _accessTokenKey, value: token);
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    return await _secureStorage!.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
    } else {
      await _secureStorage!.write(key: _refreshTokenKey, value: token);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
    return await _secureStorage!.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
    } else {
      await _secureStorage!.delete(key: _accessTokenKey);
      await _secureStorage!.delete(key: _refreshTokenKey);
    }
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
