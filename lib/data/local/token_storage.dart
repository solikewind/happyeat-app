import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'happyeat_token';
const _apiBaseUrlKey = 'happyeat_api_base_url';
const _apiEnvKey = 'happyeat_api_env';

class TokenStorage {
  TokenStorage(this._secure, this._prefs);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  static Future<TokenStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TokenStorage(const FlutterSecureStorage(), prefs);
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      return _prefs.getString(_tokenKey);
    }
    return _secure.read(key: _tokenKey);
  }

  Future<void> setToken(String token) async {
    if (kIsWeb) {
      await _prefs.setString(_tokenKey, token);
      return;
    }
    await _secure.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    if (kIsWeb) {
      await _prefs.remove(_tokenKey);
      return;
    }
    await _secure.delete(key: _tokenKey);
  }

  String? getApiBaseUrl() => _prefs.getString(_apiBaseUrlKey);

  Future<void> setApiBaseUrl(String url) =>
      _prefs.setString(_apiBaseUrlKey, url);

  String? getApiEnv() => _prefs.getString(_apiEnvKey);

  Future<void> setApiEnv(String env) => _prefs.setString(_apiEnvKey, env);
}
