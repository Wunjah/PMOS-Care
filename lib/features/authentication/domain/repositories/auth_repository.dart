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

  Future<UserEntity> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserEntity> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> deleteUserAccount();

  Future<void> saveUserProfile(UserEntity user);

  Future<UserEntity?> getCurrentUser();

  Future<void> logout();
}
