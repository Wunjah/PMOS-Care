import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUsecase {
  final AuthRepository repository;

  VerifyOtpUsecase(this.repository);

  Future<UserEntity> execute({
    required String verificationId,
    required String smsCode,
  }) async {
    if (smsCode.length != 6) {
      throw Exception('Verification code must contain exactly 6 digits.');
    }
    return await repository.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}
