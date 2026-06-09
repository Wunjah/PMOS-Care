import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _usePhoneLogin = false;

  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+237';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      if (_usePhoneLogin) {
        final formattedNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
        ref.read(authStateNotifierProvider.notifier).sendPhoneOtp(formattedNumber);
      } else {
        ref.read(authStateNotifierProvider.notifier).signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateNotifierProvider, (previous, next) {
      if (next is AuthOtpSent) {
        context.push('/otp');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: AppTheme.glycemicHigh),
        );
      } else if (next is AuthAuthenticated) {
        if (next.user.isOnboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/welcome-success');
        }
      }
    });

    final authState = ref.watch(authStateNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.health_and_safety,
                    size: 72,
                    color: AppTheme.primaryWellness,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to manage your hormones, track cycles and view advice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!_usePhoneLogin) ...[
                    // Email Login Fields
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        return null;
                      },
                    ),
                  ] else ...[
                    // Phone Login Fields
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
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
                            decoration: const InputDecoration(
                              hintText: '670 000 000',
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: _validateCameroonNumber,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Switch Login Mode
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _usePhoneLogin = !_usePhoneLogin),
                      child: Text(
                        _usePhoneLogin ? 'Use Email instead' : 'Use Phone Number instead',
                        style: const TextStyle(color: AppTheme.primaryWellness, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryWellness,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_usePhoneLogin ? 'Send OTP' : 'Login', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('OR', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google Sign In
                  OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authStateNotifierProvider.notifier).signInWithGoogle(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Don\'t have an account? ', style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(color: AppTheme.primaryWellness, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
