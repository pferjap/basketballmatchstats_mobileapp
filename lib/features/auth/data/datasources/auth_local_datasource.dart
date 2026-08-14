import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/token_storage.dart';
import '../../domain/entities/auth_tokens.dart';
import '../models/user_model.dart';

/// Local persistence of the auth session in `flutter_secure_storage`.
///
/// Token storage is delegated to the shared [TokenStorage] (same keys the Dio
/// auth interceptor reads), while the signed-in user is cached as JSON under a
/// dedicated key so the session can be restored offline.
class AuthLocalDataSource {
  AuthLocalDataSource({
    required this.tokenStorage,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final TokenStorage tokenStorage;
  final FlutterSecureStorage _storage;

  static const String _userKey = 'ha_current_user';

  Future<void> saveTokens(AuthTokens tokens) => tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

  Future<String?> readAccessToken() => tokenStorage.readAccessToken();

  Future<String?> readRefreshToken() => tokenStorage.readRefreshToken();

  Future<void> cacheUser(UserModel user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<UserModel?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) {
      return null;
    }
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await tokenStorage.clear();
    await _storage.delete(key: _userKey);
  }
}
