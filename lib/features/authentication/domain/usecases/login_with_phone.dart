import '../repositories/auth_repository.dart';

class LoginWithPhoneUsecase {
  final AuthRepository repository;

  LoginWithPhoneUsecase(this.repository);

  Future<void> execute({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Exception error) onError,
  }) async {
    if (phoneNumber.isEmpty || !phoneNumber.startsWith('+')) {
      onError(Exception('Invalid phone number format. Must include country code (+237).'));
      return;
    }
    return await repository.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
}
