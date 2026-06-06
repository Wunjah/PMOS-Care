import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_with_phone.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(secureStorageProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(firebaseAuthProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});

final loginWithPhoneUsecaseProvider = Provider<LoginWithPhoneUsecase>((ref) {
  return LoginWithPhoneUsecase(ref.watch(authRepositoryProvider));
});

final verifyOtpUsecaseProvider = Provider<VerifyOtpUsecase>((ref) {
  return VerifyOtpUsecase(ref.watch(authRepositoryProvider));
});

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  const AuthOtpSent({required this.verificationId, required this.phoneNumber});
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginWithPhoneUsecase _loginWithPhoneUsecase;
  final VerifyOtpUsecase _verifyOtpUsecase;
  final AuthRepository _authRepository;
  final AuthLocalDataSource _localDataSource;

  AuthNotifier({
    required LoginWithPhoneUsecase loginWithPhoneUsecase,
    required VerifyOtpUsecase verifyOtpUsecase,
    required AuthRepository authRepository,
    required AuthLocalDataSource localDataSource,
  })  : _loginWithPhoneUsecase = loginWithPhoneUsecase,
        _verifyOtpUsecase = verifyOtpUsecase,
        _authRepository = authRepository,
        _localDataSource = localDataSource,
        super(const AuthInitial()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    state = const AuthLoading();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthError('Session check failed: $e');
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    state = const AuthLoading();
    try {
      await _loginWithPhoneUsecase.execute(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          state = AuthOtpSent(verificationId: verificationId, phoneNumber: phoneNumber);
        },
        onError: (error) {
          state = AuthError('Verification failed: ${error.toString()}');
        },
      );
    } catch (e) {
      state = AuthError('Error sending code: $e');
    }
  }

  Future<void> verifySmsCode(String smsCode) async {
    final currentState = state;
    if (currentState is! AuthOtpSent) {
      state = const AuthError('Session state mismatch. Please request a new code.');
      return;
    }

    state = const AuthLoading();
    try {
      final user = await _verifyOtpUsecase.execute(
        verificationId: currentState.verificationId,
        smsCode: smsCode,
      );
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError('Code validation error: ${e.toString()}');
      state = AuthOtpSent(
        verificationId: currentState.verificationId,
        phoneNumber: currentState.phoneNumber,
      );
    }
  }

  Future<void> completeOnboarding() async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      await _localDataSource.setOnboardingCompleted(true);
      final updatedUser = currentState.user.copyWith(isOnboardingCompleted: true);
      state = AuthAuthenticated(updatedUser);
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _authRepository.logout();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Signout error: $e');
    }
  }
}

final authStateNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginWithPhoneUsecase: ref.watch(loginWithPhoneUsecaseProvider),
    verifyOtpUsecase: ref.watch(verifyOtpUsecaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
});
