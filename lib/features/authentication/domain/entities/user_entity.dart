class UserEntity {
  final String uid;
  final String phoneNumber;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isOnboardingCompleted;
  
  // Health Profile Fields
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? country;
  final String? region;
  final String? pmosDiagnosisStatus;
  final List<String> medications;
  final List<String> allergies;
  final List<String> goals;
  
  // Settings
  final bool biometricLockEnabled;
  final bool notificationsEnabled;

  const UserEntity({
    required this.uid,
    required this.phoneNumber,
    this.email,
    required this.displayName,
    this.photoUrl,
    required this.isOnboardingCompleted,
    this.age,
    this.heightCm,
    this.weightKg,
    this.country,
    this.region,
    this.pmosDiagnosisStatus,
    this.medications = const [],
    this.allergies = const [],
    this.goals = const [],
    this.biometricLockEnabled = false,
    this.notificationsEnabled = false,
  });

  UserEntity copyWith({
    String? uid,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isOnboardingCompleted,
    int? age,
    double? heightCm,
    double? weightKg,
    String? country,
    String? region,
    String? pmosDiagnosisStatus,
    List<String>? medications,
    List<String>? allergies,
    List<String>? goals,
    bool? biometricLockEnabled,
    bool? notificationsEnabled,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      country: country ?? this.country,
      region: region ?? this.region,
      pmosDiagnosisStatus: pmosDiagnosisStatus ?? this.pmosDiagnosisStatus,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      goals: goals ?? this.goals,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

