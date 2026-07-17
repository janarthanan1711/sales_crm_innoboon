import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// Local datasource for auth — token/user persistence
abstract class AuthLocalDataSource {
  Future<void> saveUser(UserModel user);
  Future<void> saveAccessToken(String accessToken);
  Future<UserModel?> getCachedUser();
  Future<String?> getAccessToken();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  static const String _userKey = 'cached_user';
  static const String _accessTokenKey = 'access_token';

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveUser(UserModel user) async {
    await secureStorage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    await secureStorage.write(key: _accessTokenKey, value: accessToken);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = await secureStorage.read(key: _userKey);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  @override
  Future<String?> getAccessToken() async {
    return secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<void> clearAll() async {
    await secureStorage.delete(key: _userKey);
    await secureStorage.delete(key: _accessTokenKey);
  }
}
