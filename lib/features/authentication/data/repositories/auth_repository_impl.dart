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

  UserModel _buildModel(UserModel src, {required bool onboarding}) {
    return UserModel(
      uid: src.uid,
      phoneNumber: src.phoneNumber,
      email: src.email,
      displayName: src.displayName,
      photoUrl: src.photoUrl,
      isOnboardingCompleted: onboarding || src.isOnboardingCompleted,
      role: src.role,
      age: src.age,
      heightCm: src.heightCm,
      weightKg: src.weightKg,
      country: src.country,
      region: src.region,
      pmosDiagnosisStatus: src.pmosDiagnosisStatus,
      medications: src.medications,
      allergies: src.allergies,
      goals: src.goals,
      specialty: src.specialty,
      hospitalClinic: src.hospitalClinic,
      yearsExperience: src.yearsExperience,
      licenseNumber: src.licenseNumber,
      biometricLockEnabled: src.biometricLockEnabled,
      notificationsEnabled: src.notificationsEnabled,
    );
  }

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
    final onboarding = await localDataSource.isOnboardingCompleted();
    final result = _buildModel(userModel, onboarding: onboarding);
    await localDataSource.cacheUser(result);
    return result;
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'patient',
  }) async {
    final userModel = await remoteDataSource.signUpWithEmailAndPassword(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );
    final onboarding = await localDataSource.isOnboardingCompleted();
    final result = _buildModel(userModel, onboarding: onboarding);
    await localDataSource.cacheUser(result);
    return result;
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
    final onboarding = await localDataSource.isOnboardingCompleted();
    final result = _buildModel(userModel, onboarding: onboarding);
    await localDataSource.cacheUser(result);
    return result;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final userModel = await remoteDataSource.signInWithGoogle();
    final onboarding = await localDataSource.isOnboardingCompleted();
    final result = _buildModel(userModel, onboarding: onboarding);
    await localDataSource.cacheUser(result);
    return result;
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
    final remoteUser = await remoteDataSource.getCurrentUser();
    if (remoteUser == null) {
      await localDataSource.clearCache();
      return null;
    }

    final cachedUser = await localDataSource.getCachedUser();
    if (cachedUser != null && cachedUser.uid == remoteUser.uid) {
      return cachedUser;
    }

    final onboarding = await localDataSource.isOnboardingCompleted();
    final result = _buildModel(remoteUser, onboarding: onboarding);
    await localDataSource.cacheUser(result);
    return result;
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearCache();
  }
}
