import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/features/authentication/domain/entities/user_entity.dart';
import 'package:pmos_care/features/authentication/domain/repositories/auth_repository.dart';
import 'package:pmos_care/features/authentication/domain/usecases/verify_otp.dart';

/// Lightweight Mock implementation of AuthRepository for unit tests
class MockAuthRepository implements AuthRepository {
  bool sendOtpCalled = false;
  bool verifyOtpCalled = false;
  bool getCurrentUserCalled = false;
  bool logoutCalled = false;

  final UserEntity mockUser = const UserEntity(
    uid: 'mock_uid_123',
    phoneNumber: '+237670000000',
    displayName: 'Mock User',
    isOnboardingCompleted: false,
  );

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Exception error) onError,
  }) async {
    sendOtpCalled = true;
    onCodeSent('mock_verification_id');
  }

  @override
  Future<UserEntity> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyOtpCalled = true;
    if (smsCode == '123456') {
      return mockUser;
    } else {
      throw Exception('Invalid verification code.');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    getCurrentUserCalled = true;
    return mockUser;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  late MockAuthRepository mockRepository;
  late VerifyOtpUsecase verifyOtpUsecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    verifyOtpUsecase = VerifyOtpUsecase(mockRepository);
  });

  group('VerifyOtpUsecase Unit Tests', () {
    test('should return UserEntity when smsCode is valid and 6 digits', () async {
      // Arrange
      const verificationId = 'mock_id';
      const validSmsCode = '123456';

      // Act
      final result = await verifyOtpUsecase.execute(
        verificationId: verificationId,
        smsCode: validSmsCode,
      );

      // Assert
      expect(result.uid, equals('mock_uid_123'));
      expect(result.phoneNumber, equals('+237670000000'));
      expect(mockRepository.verifyOtpCalled, isTrue);
    });

    test('should throw exception when smsCode is not exactly 6 digits', () async {
      // Arrange
      const verificationId = 'mock_id';
      const shortSmsCode = '1234';

      // Act & Assert
      expect(
        () => verifyOtpUsecase.execute(
          verificationId: verificationId,
          smsCode: shortSmsCode,
        ),
        throwsA(isA<Exception>()),
      );
      expect(mockRepository.verifyOtpCalled, isFalse);
    });

    test('should throw exception when repository verifyOtp fails', () async {
      // Arrange
      const verificationId = 'mock_id';
      const wrongSmsCode = '000000'; // Mock verification rejects non-123456

      // Act & Assert
      expect(
        () => verifyOtpUsecase.execute(
          verificationId: verificationId,
          smsCode: wrongSmsCode,
        ),
        throwsA(isA<Exception>()),
      );
      expect(mockRepository.verifyOtpCalled, isTrue);
    });
  });
}
