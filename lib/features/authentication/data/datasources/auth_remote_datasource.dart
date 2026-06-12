import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Exception error) onError,
  });

  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'patient',
  });

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> deleteUserAccount();

  Future<void> saveUserProfile(UserModel user);

  Future<UserModel?> getCurrentUser();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._firebaseAuth, this._firestore);

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(Exception error) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError(Exception('Failed to trigger phone verification: $e'));
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Authentication returned empty user session.');
    }

    // Fetch user profile from Firestore if it exists
    UserModel? cachedUser;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        cachedUser = UserModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    final finalUser = cachedUser ?? UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      email: user.email,
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      isOnboardingCompleted: false,
    );

    if (cachedUser == null) {
      await saveUserProfile(finalUser);
    }
    return finalUser;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'patient',
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Signup returned empty user session.');

    await user.updateDisplayName(name);

    final userModel = UserModel(
      uid: user.uid,
      phoneNumber: phone,
      email: email,
      displayName: name,
      photoUrl: null,
      isOnboardingCompleted: false,
      role: role,
    );

    await saveUserProfile(userModel);
    return userModel;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) throw Exception('Sign in returned empty user session.');

    UserModel? cachedUser;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        cachedUser = UserModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    return cachedUser ?? UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      email: email,
      displayName: user.displayName ?? email.split('@')[0],
      photoUrl: user.photoURL,
      isOnboardingCompleted: false,
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by the user.');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    final User? user = userCredential.user;
    if (user == null) throw Exception('Google Sign-In returned empty user session.');

    UserModel? cachedUser;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        cachedUser = UserModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    final finalUser = cachedUser ?? UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      email: user.email,
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      isOnboardingCompleted: false,
    );

    if (cachedUser == null) {
      await saveUserProfile(finalUser);
    }
    return finalUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> deleteUserAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found to delete.');

    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (_) {}

    await user.delete();
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(
      user.toJson(),
      SetOptions(merge: true),
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (_) {}

    return UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      email: user.email,
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      isOnboardingCompleted: false,
    );
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await GoogleSignIn().signOut().catchError((_) => null);
  }
}
