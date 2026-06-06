import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP code cannot be empty';
    }
    if (value.length != 6 || int.tryParse(value) == null) {
      return 'OTP must be exactly 6 numeric digits';
    }
    return null;
  }

  void _submitOtp() {
    if (_formKey.currentState!.validate()) {
      ref.read(authStateNotifierProvider.notifier).verifySmsCode(_otpController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        if (next.user.isOnboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.glycemicHigh,
          ),
        );
      }
    });

    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState is AuthLoading;
    final String phoneNumber = authState is AuthOtpSent ? authState.phoneNumber : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('otp_title'),
          style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(
                  Icons.sms_outlined,
                  size: 80,
                  color: AppTheme.primaryWellness,
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter Code sent to $phoneNumber',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryWellness,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter the 6 digit verification code sent to your mobile phone number. Do not share this code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    hintText: '000000',
                    labelText: 'Verification Code',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryWellness, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  validator: _validateOtp,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitOtp,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(context.translate('verify')),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.pop();
                        },
                  child: const Text(
                    'Change Phone Number',
                    style: TextStyle(color: AppTheme.primaryWellness),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
