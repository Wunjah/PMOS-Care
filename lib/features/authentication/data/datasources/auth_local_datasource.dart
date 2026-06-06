import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCache();
  Future<bool> isOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool completed);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  static const String _userCacheKey = 'pmos_cached_user';
  static const String _onboardingKey = 'pmos_onboarding_completed';

  AuthLocalDataSourceImpl(this._secureStorage);

  @override
  Future<void> cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _secureStorage.write(key: _userCacheKey, value: userJson);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = await _secureStorage.read(key: _userCacheKey);
    if (userJson == null) return null;
    try {
      final jsonMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _secureStorage.delete(key: _userCacheKey);
    await _secureStorage.delete(key: _onboardingKey);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final value = await _secureStorage.read(key: _onboardingKey);
    return value == 'true';
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _secureStorage.write(
      key: _onboardingKey,
      value: completed ? 'true' : 'false',
    );
  }
}
