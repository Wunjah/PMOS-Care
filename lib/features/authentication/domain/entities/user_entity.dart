class UserEntity {
  final String uid;
  final String phoneNumber;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isOnboardingCompleted;

  const UserEntity({
    required this.uid,
    required this.phoneNumber,
    this.email,
    required this.displayName,
    this.photoUrl,
    required this.isOnboardingCompleted,
  });

  UserEntity copyWith({
    String? uid,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isOnboardingCompleted,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }
}
