import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Exception error) onError,
  });

  Future<UserEntity> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<UserEntity?> getCurrentUser();

  Future<void> logout();
}
