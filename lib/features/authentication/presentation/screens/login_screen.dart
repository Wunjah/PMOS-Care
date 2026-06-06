import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+237';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateCameroonNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number cannot be empty';
    }
    final cleanValue = value.replaceAll(RegExp(r'\s+|-'), '');
    if (cleanValue.length != 9) {
      return 'Cameroon numbers must have exactly 9 digits';
    }
    final firstDigit = cleanValue[0];
    if (firstDigit != '6' && firstDigit != '2') {
      return 'Number must start with a valid carrier code (e.g. 6)';
    }
    return null;
  }

  void _submitPhoneNumber() {
    if (_formKey.currentState!.validate()) {
      final formattedNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      ref.read(authStateNotifierProvider.notifier).sendPhoneOtp(formattedNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
      if (next is AuthOtpSent) {
        context.push('/otp');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.glycemicHigh,
          ),
        );
      } else if (next is AuthAuthenticated) {
        if (next.user.isOnboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/onboarding');
        }
      }
    });

    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.translate('login_title'),
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
                  Icons.health_and_safety_outlined,
                  size: 80,
                  color: AppTheme.primaryWellness,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to PMOS Care',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryWellness,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Empowering Cameroonian women to manage PMOS. Enter your phone number to proceed securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        underline: const SizedBox(),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCountryCode = val;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: '+237', child: Text('🇨🇲 +237')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          hintText: '670 000 000',
                          labelText: context.translate('phone_hint'),
                          border: const OutlineInputBorder(),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primaryWellness, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: _validateCameroonNumber,
                        enabled: !isLoading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitPhoneNumber,
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(context.translate('send_otp')),
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
