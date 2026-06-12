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

class SpecialistOnboardingScreen extends ConsumerStatefulWidget {
  const SpecialistOnboardingScreen({super.key});

  @override
  ConsumerState<SpecialistOnboardingScreen> createState() => _SpecialistOnboardingScreenState();
}

class _SpecialistOnboardingScreenState extends ConsumerState<SpecialistOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedSpecialty = 'Gynecologist / OB-GYN';
  bool _isSaving = false;

  final List<String> _specialties = [
    'Gynecologist / OB-GYN',
    'Endocrinologist',
    'PCOS / PMOS Specialist',
    'Nutritionist / Dietitian',
    'General Practitioner',
    'Dermatologist',
    'Psychiatrist / Mental Health',
    'Physiotherapist',
  ];

  @override
  void dispose() {
    _hospitalController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    await ref.read(authStateNotifierProvider.notifier).saveSpecialistProfile(
          specialty: _selectedSpecialty,
          hospitalClinic: _hospitalController.text.trim(),
          yearsExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
          licenseNumber: _licenseController.text.trim(),
        );

    setState(() => _isSaving = false);
    if (mounted) context.go('/home');
  }

  void _skip() {
    ref.read(authStateNotifierProvider.notifier).completeOnboarding();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 80, bottom: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00696A), Color(0xFF45A8A9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF00696A).withOpacity(0.3), blurRadius: 16),
                          ],
                        ),
                        child: const Icon(Icons.medical_services, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Complete Your Profile',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.bold, color: _kDarkText),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Help patients find and trust you by completing your professional profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: _kMutedText),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildLabel('Specialty'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSpecialty,
                      decoration: _inputDecoration('Select your specialty'),
                      items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Inter')))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _selectedSpecialty = v); },
                      validator: (v) => v == null ? 'Please select a specialty' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Hospital / Clinic'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hospitalController,
                      decoration: _inputDecoration('e.g. Yaoundé Central Hospital'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your institution' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Medical License Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _licenseController,
                      decoration: _inputDecoration('Your official license number'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your license number' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Years of Experience'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _experienceController,
                      decoration: _inputDecoration('e.g. 8'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter years of experience';
                        if (int.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Complete Profile', style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(fontFamily: 'Inter', color: _kMutedText, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 44, bottom: 12),
            decoration: const BoxDecoration(
              color: Color(0xCCF8F9FF),
              border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
            ),
            child: const Text(
              'Specialist Setup',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.bold, color: _kDarkText),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600, color: _kDarkText),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Inter', color: _kMutedText, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }
}
