import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _statusMessage = 'PMOS Care is Locked';

  @override
  void initState() {
    super.initState();
    // Trigger biometric prompt automatically on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'Biometric hardware unavailable or not set up.';
        });
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please scan your fingerprint or face to unlock PMOS Care',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        if (!mounted) return;
        final authState = ref.read(authStateNotifierProvider);
        if (authState is AuthAuthenticated) {
          if (authState.user.isOnboardingCompleted) {
            context.go('/home');
          } else {
            context.go('/welcome-success');
          }
        } else {
          context.go('/login');
        }
      } else {
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'Authentication failed. Tap button to retry.';
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Error authenticating: $e';
      });
    }
  }

  void _bypassLock() {
    // Fallback bypass: Log out the current user session and redirect back to login screen
    ref.read(authStateNotifierProvider.notifier).logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.lock_person_outlined,
                size: 80,
                color: AppTheme.primaryWellness,
              ),
              const SizedBox(height: 24),
              const Text(
                'Security Check Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: const Text(
                  'Unlock App',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _bypassLock,
                child: const Text(
                  'Bypass Lock / Log In Again',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.primaryWellness, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
