class UserEntity {
  final String uid;
  final String phoneNumber;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isOnboardingCompleted;
  final String role; // 'patient' | 'doctor'

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

  // Specialist Profile Fields (for doctors)
  final String? specialty;
  final String? hospitalClinic;
  final int? yearsExperience;
  final String? licenseNumber;

  // Skin Profile Fields
  final String? skinAcneSeverity;
  final List<String> skinAffectedAreas;

  // Connected Apps Fields
  final bool syncHeartRate;
  final bool syncDailySteps;
  final bool syncBloodGlucose;
  final bool googleFitConnected;

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
    this.role = 'patient',
    this.age,
    this.heightCm,
    this.weightKg,
    this.country,
    this.region,
    this.pmosDiagnosisStatus,
    this.medications = const [],
    this.allergies = const [],
    this.goals = const [],
    this.specialty,
    this.hospitalClinic,
    this.yearsExperience,
    this.licenseNumber,
    this.skinAcneSeverity,
    this.skinAffectedAreas = const [],
    this.syncHeartRate = true,
    this.syncDailySteps = true,
    this.syncBloodGlucose = false,
    this.googleFitConnected = false,
    this.biometricLockEnabled = false,
    this.notificationsEnabled = false,
  });

  bool get isDoctor => role == 'doctor';

  UserEntity copyWith({
    String? uid,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isOnboardingCompleted,
    String? role,
    int? age,
    double? heightCm,
    double? weightKg,
    String? country,
    String? region,
    String? pmosDiagnosisStatus,
    List<String>? medications,
    List<String>? allergies,
    List<String>? goals,
    String? specialty,
    String? hospitalClinic,
    int? yearsExperience,
    String? licenseNumber,
    String? skinAcneSeverity,
    List<String>? skinAffectedAreas,
    bool? syncHeartRate,
    bool? syncDailySteps,
    bool? syncBloodGlucose,
    bool? googleFitConnected,
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
      role: role ?? this.role,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      country: country ?? this.country,
      region: region ?? this.region,
      pmosDiagnosisStatus: pmosDiagnosisStatus ?? this.pmosDiagnosisStatus,
      medications: medications ?? this.medications,
      allergies: allergies ?? this.allergies,
      goals: goals ?? this.goals,
      specialty: specialty ?? this.specialty,
      hospitalClinic: hospitalClinic ?? this.hospitalClinic,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      skinAcneSeverity: skinAcneSeverity ?? this.skinAcneSeverity,
      skinAffectedAreas: skinAffectedAreas ?? this.skinAffectedAreas,
      syncHeartRate: syncHeartRate ?? this.syncHeartRate,
      syncDailySteps: syncDailySteps ?? this.syncDailySteps,
      syncBloodGlucose: syncBloodGlucose ?? this.syncBloodGlucose,
      googleFitConnected: googleFitConnected ?? this.googleFitConnected,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
