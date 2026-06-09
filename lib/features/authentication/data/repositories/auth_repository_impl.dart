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
      age: userModel.age,
      heightCm: userModel.heightCm,
      weightKg: userModel.weightKg,
      country: userModel.country,
      region: userModel.region,
      pmosDiagnosisStatus: userModel.pmosDiagnosisStatus,
      medications: userModel.medications,
      allergies: userModel.allergies,
      goals: userModel.goals,
      biometricLockEnabled: userModel.biometricLockEnabled,
      notificationsEnabled: userModel.notificationsEnabled,
    );

    await localDataSource.cacheUser(finalUserModel);
    return finalUserModel;
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final userModel = await remoteDataSource.signUpWithEmailAndPassword(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );

    final onboardingCompleted = await localDataSource.isOnboardingCompleted();
    final finalUserModel = UserModel(
      uid: userModel.uid,
      phoneNumber: userModel.phoneNumber,
      email: userModel.email,
      displayName: userModel.displayName,
      photoUrl: userModel.photoUrl,
      isOnboardingCompleted: onboardingCompleted,
      age: userModel.age,
      heightCm: userModel.heightCm,
      weightKg: userModel.weightKg,
      country: userModel.country,
      region: userModel.region,
      pmosDiagnosisStatus: userModel.pmosDiagnosisStatus,
      medications: userModel.medications,
      allergies: userModel.allergies,
      goals: userModel.goals,
      biometricLockEnabled: userModel.biometricLockEnabled,
      notificationsEnabled: userModel.notificationsEnabled,
    );

    await localDataSource.cacheUser(finalUserModel);
    return finalUserModel;
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userModel = await remoteDataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final onboardingCompleted = await localDataSource.isOnboardingCompleted();
    final finalUserModel = UserModel(
      uid: userModel.uid,
      phoneNumber: userModel.phoneNumber,
      email: userModel.email,
      displayName: userModel.displayName,
      photoUrl: userModel.photoUrl,
      isOnboardingCompleted: onboardingCompleted || userModel.isOnboardingCompleted,
      age: userModel.age,
      heightCm: userModel.heightCm,
      weightKg: userModel.weightKg,
      country: userModel.country,
      region: userModel.region,
      pmosDiagnosisStatus: userModel.pmosDiagnosisStatus,
      medications: userModel.medications,
      allergies: userModel.allergies,
      goals: userModel.goals,
      biometricLockEnabled: userModel.biometricLockEnabled,
      notificationsEnabled: userModel.notificationsEnabled,
    );

    await localDataSource.cacheUser(finalUserModel);
    return finalUserModel;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final userModel = await remoteDataSource.signInWithGoogle();

    final onboardingCompleted = await localDataSource.isOnboardingCompleted();
    final finalUserModel = UserModel(
      uid: userModel.uid,
      phoneNumber: userModel.phoneNumber,
      email: userModel.email,
      displayName: userModel.displayName,
      photoUrl: userModel.photoUrl,
      isOnboardingCompleted: onboardingCompleted || userModel.isOnboardingCompleted,
      age: userModel.age,
      heightCm: userModel.heightCm,
      weightKg: userModel.weightKg,
      country: userModel.country,
      region: userModel.region,
      pmosDiagnosisStatus: userModel.pmosDiagnosisStatus,
      medications: userModel.medications,
      allergies: userModel.allergies,
      goals: userModel.goals,
      biometricLockEnabled: userModel.biometricLockEnabled,
      notificationsEnabled: userModel.notificationsEnabled,
    );

    await localDataSource.cacheUser(finalUserModel);
    return finalUserModel;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> deleteUserAccount() async {
    await remoteDataSource.deleteUserAccount();
    await localDataSource.clearCache();
  }

  @override
  Future<void> saveUserProfile(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await remoteDataSource.saveUserProfile(model);
    await localDataSource.cacheUser(model);
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
        isOnboardingCompleted: onboarding || remoteUser.isOnboardingCompleted,
        age: remoteUser.age,
        heightCm: remoteUser.heightCm,
        weightKg: remoteUser.weightKg,
        country: remoteUser.country,
        region: remoteUser.region,
        pmosDiagnosisStatus: remoteUser.pmosDiagnosisStatus,
        medications: remoteUser.medications,
        allergies: remoteUser.allergies,
        goals: remoteUser.goals,
        biometricLockEnabled: remoteUser.biometricLockEnabled,
        notificationsEnabled: remoteUser.notificationsEnabled,
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
