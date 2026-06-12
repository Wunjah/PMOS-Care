import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kMutedText = Color(0xFF777684);
const _kBg = Color(0xFFF8F9FF);
const _kDivider = Color(0xFFE7E8EE);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _usePhoneLogin = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_usePhoneLogin) {
        ref.read(authStateNotifierProvider.notifier)
            .sendPhoneOtp('+237${_phoneController.text.trim()}');
      } else {
        ref.read(authStateNotifierProvider.notifier).signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateNotifierProvider, (_, next) {
      if (next is AuthOtpSent) {
        context.push('/otp');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red.shade700),
        );
      } else if (next is AuthAuthenticated) {
        if (next.user.biometricLockEnabled) {
          context.go('/lock');
        } else if (next.user.isOnboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/welcome-success');
        }
      }
    });

    final isLoading = ref.watch(authStateNotifierProvider) is AuthLoading;

    return Scaffold(
      backgroundColor: _kBg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Login mode toggle
                      _ModeToggle(
                        usePhone: _usePhoneLogin,
                        onToggle: (v) => setState(() => _usePhoneLogin = v),
                      ),
                      const SizedBox(height: 28),

                      if (!_usePhoneLogin) ...[
                        _buildField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          type: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPassword,
                            child: const Text('Forgot Password?',
                                style: TextStyle(color: _kPrimary, fontFamily: 'Inter', fontSize: 13)),
                          ),
                        ),
                      ] else ...[
                        _buildPhoneField(),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 20),
                      _buildPrimaryButton(isLoading),
                      const SizedBox(height: 28),
                      _buildDivider(),
                      const SizedBox(height: 28),
                      _buildGoogleButton(isLoading),
                      const SizedBox(height: 32),
                      _buildSignupLink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, Color(0xFF6C6DD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'PMOS Care',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue your health journey',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _kMutedText,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: _inputDecoration('Phone Number (e.g. 670 000 000)', Icons.phone_outlined).copyWith(
        prefixText: '+237  ',
        prefixStyle: const TextStyle(color: _kDarkText, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
        final clean = v.replaceAll(RegExp(r'\s+|-'), '');
        if (clean.length != 9) return 'Must be 9 digits (e.g. 670000000)';
        return null;
      },
    );
  }

  Widget _buildPrimaryButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              _usePhoneLogin ? 'Send OTP' : 'Sign In',
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: _kDivider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR CONTINUE WITH',
              style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kMutedText, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        const Expanded(child: Divider(color: _kDivider)),
      ],
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return OutlinedButton(
      onPressed: isLoading
          ? null
          : () => ref.read(authStateNotifierProvider.notifier).signInWithGoogle(),
      style: OutlinedButton.styleFrom(
        foregroundColor: _kDarkText,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: _kDivider, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
          ),
          const SizedBox(width: 10),
          const Text(
            'Continue with Google',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('New to PMOS Care? ',
            style: TextStyle(fontFamily: 'Inter', color: _kMutedText, fontSize: 14)),
        GestureDetector(
          onTap: () => context.go('/signup'),
          child: const Text(
            'Create Account',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: _kPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPassword() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reset Password',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Enter your email and we\'ll send a reset link.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: _kMutedText)),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email Address', Icons.email_outlined),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.trim().isNotEmpty) {
                    ref.read(authStateNotifierProvider.notifier).resetPassword(ctrl.text.trim());
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset email sent!'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Send Reset Link', style: TextStyle(color: Colors.white, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Inter', color: _kMutedText, fontSize: 14),
      prefixIcon: Icon(icon, color: _kPrimary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool usePhone;
  final ValueChanged<bool> onToggle;
  const _ModeToggle({required this.usePhone, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Tab(label: 'Email', icon: Icons.email_outlined, selected: !usePhone, onTap: () => onToggle(false)),
          _Tab(label: 'Phone / OTP', icon: Icons.phone_outlined, selected: usePhone, onTap: () => onToggle(true)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? const Color(0xFF5152B9) : const Color(0xFF777684)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? const Color(0xFF5152B9) : const Color(0xFF777684),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
