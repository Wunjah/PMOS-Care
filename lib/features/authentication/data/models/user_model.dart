import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.phoneNumber,
    super.email,
    required super.displayName,
    super.photoUrl,
    required super.isOnboardingCompleted,
    super.age,
    super.heightCm,
    super.weightKg,
    super.country,
    super.region,
    super.pmosDiagnosisStatus,
    super.medications,
    super.allergies,
    super.goals,
    super.biometricLockEnabled,
    super.notificationsEnabled,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isOnboardingCompleted: json['isOnboardingCompleted'] as bool? ?? false,
      age: json['age'] as int?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      country: json['country'] as String?,
      region: json['region'] as String?,
      pmosDiagnosisStatus: json['pmosDiagnosisStatus'] as String?,
      medications: List<String>.from(json['medications'] as List? ?? []),
      allergies: List<String>.from(json['allergies'] as List? ?? []),
      goals: List<String>.from(json['goals'] as List? ?? []),
      biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isOnboardingCompleted': isOnboardingCompleted,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'country': country,
      'region': region,
      'pmosDiagnosisStatus': pmosDiagnosisStatus,
      'medications': medications,
      'allergies': allergies,
      'goals': goals,
      'biometricLockEnabled': biometricLockEnabled,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      isOnboardingCompleted: entity.isOnboardingCompleted,
      age: entity.age,
      heightCm: entity.heightCm,
      weightKg: entity.weightKg,
      country: entity.country,
      region: entity.region,
      pmosDiagnosisStatus: entity.pmosDiagnosisStatus,
      medications: entity.medications,
      allergies: entity.allergies,
      goals: entity.goals,
      biometricLockEnabled: entity.biometricLockEnabled,
      notificationsEnabled: entity.notificationsEnabled,
    );
  }
}

