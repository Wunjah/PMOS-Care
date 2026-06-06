import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Exception error) onError,
  }) async {
    return await remoteDataSource.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  @override
  Future<UserEntity> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final userModel = await remoteDataSource.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    
    final onboardingCompleted = await localDataSource.isOnboardingCompleted();
    final finalUserModel = UserModel(
      uid: userModel.uid,
      phoneNumber: userModel.phoneNumber,
      email: userModel.email,
      displayName: userModel.displayName,
      photoUrl: userModel.photoUrl,
      isOnboardingCompleted: onboardingCompleted,
    );

    await localDataSource.cacheUser(finalUserModel);
    return finalUserModel;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final cachedUser = await localDataSource.getCachedUser();
    if (cachedUser != null) {
      return cachedUser;
    }

    final remoteUser = await remoteDataSource.getCurrentUser();
    if (remoteUser != null) {
      final onboarding = await localDataSource.isOnboardingCompleted();
      final finalUser = UserModel(
        uid: remoteUser.uid,
        phoneNumber: remoteUser.phoneNumber,
        email: remoteUser.email,
        displayName: remoteUser.displayName,
        photoUrl: remoteUser.photoUrl,
        isOnboardingCompleted: onboarding,
      );
      await localDataSource.cacheUser(finalUser);
      return finalUser;
    }

    return null;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearCache();
  }
}
