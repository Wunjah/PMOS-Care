import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kMutedText = Color(0xFF777684);
const _kDivider = Color(0xFFE7E8EE);
const _kBg = Color(0xFFF8F9FF);

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'patient';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authStateNotifierProvider.notifier).signUpWithEmailAndPassword(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateNotifierProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red.shade700),
        );
      } else if (next is AuthAuthenticated) {
        if (next.user.isDoctor) {
          context.go('/specialist-onboarding');
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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Role picker
                      const Text('I am a…',
                          style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold, color: _kDarkText)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _RoleCard(
                            label: 'Patient',
                            subtitle: 'Track & manage PMOS',
                            icon: Icons.favorite_outline,
                            color: _kPrimary,
                            selected: _selectedRole == 'patient',
                            onTap: () => setState(() => _selectedRole = 'patient'),
                          ),
                          const SizedBox(width: 12),
                          _RoleCard(
                            label: 'Doctor',
                            subtitle: 'Healthcare provider',
                            icon: Icons.medical_services_outlined,
                            color: const Color(0xFF00696A),
                            selected: _selectedRole == 'doctor',
                            onTap: () => setState(() => _selectedRole = 'doctor'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildField(_nameController, 'Full Name', Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                      const SizedBox(height: 14),
                      _buildField(_emailController, 'Email Address', Icons.email_outlined,
                          type: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email';
                            return null;
                          }),
                      const SizedBox(height: 14),
                      _buildField(_phoneController, 'Phone Number', Icons.phone_outlined,
                          type: TextInputType.phone,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                      const SizedBox(height: 14),
                      _buildPasswordField(_passwordController, 'Password', _obscurePassword,
                          () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          }),
                      const SizedBox(height: 14),
                      _buildPasswordField(_confirmPasswordController, 'Confirm Password', _obscureConfirm,
                          () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          }),
                      const SizedBox(height: 24),

                      ElevatedButton(
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
                            : const Text('Create Account',
                                style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: _kDivider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: _kMutedText, fontWeight: FontWeight.w600)),
                          ),
                          const Expanded(child: Divider(color: _kDivider)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      OutlinedButton(
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
                          children: const [
                            Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Sign up with Google',
                                style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(fontFamily: 'Inter', color: _kMutedText, fontSize: 14)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text('Sign In',
                                style: TextStyle(fontFamily: 'Outfit', color: _kPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => context.go('/login'),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              const Text(
                'Create Account',
                style: TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Join thousands managing PMOS across Cameroon',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: validator,
      decoration: _deco(label, icon),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool obscure,
    VoidCallback toggleObscure, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: _deco(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _kMutedText, size: 20),
          onPressed: toggleObscure,
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Inter', color: _kMutedText, fontSize: 14),
      prefixIcon: Icon(icon, color: _kPrimary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kDivider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : _kDivider,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: selected ? Colors.white : color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : _kDarkText)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: selected ? Colors.white.withOpacity(0.8) : _kMutedText)),
            ],
          ),
        ),
      ),
    );
  }
}
