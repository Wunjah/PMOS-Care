import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class HealthProfileSetupScreen extends ConsumerStatefulWidget {
  const HealthProfileSetupScreen({super.key});

  @override
  ConsumerState<HealthProfileSetupScreen> createState() => _HealthProfileSetupScreenState();
}

class _HealthProfileSetupScreenState extends ConsumerState<HealthProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String _country = 'Cameroon';
  String _region = 'Centre';
  String _pmosStatus = 'Diagnosed';
  
  // Settings switches
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  // Dynamic Chip Lists
  final List<String> _medications = [];
  final List<String> _allergies = [];
  final List<String> _goals = [];

  final _medController = TextEditingController();
  final _allergyController = TextEditingController();
  final _goalController = TextEditingController();

  final List<String> _regions = [
    'Centre',
    'Littoral',
    'West',
    'Northwest',
    'Southwest',
    'North',
    'Far North',
    'Adamawa',
    'East',
    'South'
  ];

  final List<String> _pmosStatuses = [
    'Diagnosed',
    'Suspected',
    'Not Diagnosed'
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medController.dispose();
    _allergyController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _submitProfile() {
    if (_formKey.currentState!.validate()) {
      final age = int.tryParse(_ageController.text.trim()) ?? 25;
      final height = double.tryParse(_heightController.text.trim()) ?? 160.0;
      final weight = double.tryParse(_weightController.text.trim()) ?? 65.0;

      ref.read(authStateNotifierProvider.notifier).saveHealthProfile(
            age: age,
            heightCm: height,
            weightKg: weight,
            country: _country,
            region: _region,
            pmosDiagnosisStatus: _pmosStatus,
            medications: _medications,
            allergies: _allergies,
            goals: _goals,
            biometricLockEnabled: _biometricEnabled,
            notificationsEnabled: _notificationsEnabled,
          );
      context.go('/skin-profile');
    }
  }

  Widget _buildChipSection({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(60, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onAdd,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(items.length, (idx) {
              return Chip(
                label: Text(items[idx], style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                backgroundColor: AppTheme.primaryLight,
                deleteIcon: const Icon(Icons.close, size: 14),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onDeleted: () => onRemove(idx),
              );
            }),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'Complete Health Profile',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authStateNotifierProvider.notifier).completeOnboarding();
              if (context.mounted) context.go('/home');
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryWellness,
              ),
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Hormonal Health Profile',
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
                  'This information helps us calculate custom metabolic predictions and local dietary suggestions for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Age, Height, Weight row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age (Years)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (int.tryParse(val) == null) return 'Invalid age';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (double.tryParse(val) == null) return 'Invalid height';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (double.tryParse(val) == null) return 'Invalid weight';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Location details: Country & Region
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _country,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _region,
                        decoration: const InputDecoration(
                          labelText: 'Region in Cameroon',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        items: _regions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _region = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // PMOS Diagnosis status
                DropdownButtonFormField<String>(
                  value: _pmosStatus,
                  decoration: const InputDecoration(
                    labelText: 'PMOS Diagnosis Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: _pmosStatuses.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _pmosStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),

                // Dynamic input chip sections
                _buildChipSection(
                  label: 'Medications Currently Taking (Optional)',
                  controller: _medController,
                  items: _medications,
                  hintText: 'e.g. Metformin',
                  onAdd: () {
                    final txt = _medController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        _medications.add(txt);
                        _medController.clear();
                      });
                    }
                  },
                  onRemove: (idx) {
                    setState(() => _medications.removeAt(idx));
                  },
                ),

                _buildChipSection(
                  label: 'Known Medical Allergies (Optional)',
                  controller: _allergyController,
                  items: _allergies,
                  hintText: 'e.g. Penicillin',
                  onAdd: () {
                    final txt = _allergyController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        _allergies.add(txt);
                        _allergyController.clear();
                      });
                    }
                  },
                  onRemove: (idx) {
                    setState(() => _allergies.removeAt(idx));
                  },
                ),

                _buildChipSection(
                  label: 'Tracking Health Goals (Optional)',
                  controller: _goalController,
                  items: _goals,
                  hintText: 'e.g. Improve ovulation regularity',
                  onAdd: () {
                    final txt = _goalController.text.trim();
                    if (txt.isNotEmpty) {
                      setState(() {
                        _goals.add(txt);
                        _goalController.clear();
                      });
                    }
                  },
                  onRemove: (idx) {
                    setState(() => _goals.removeAt(idx));
                  },
                ),

                // Settings Switches (Biometrics & Notifications)
                const Text(
                  'Preferences & Security',
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  elevation: 0,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _biometricEnabled,
                        activeColor: AppTheme.primaryWellness,
                        title: const Text('Enable Biometric Screen Lock', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                        subtitle: const Text('Fingerprint or Face ID unlock on startup', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
                        onChanged: (val) {
                          setState(() => _biometricEnabled = val);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _notificationsEnabled,
                        activeColor: AppTheme.primaryWellness,
                        title: const Text('Enable Daily Push Reminders', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                        subtitle: const Text('Get alerts for breakfast, meals, and meds', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey)),
                        onChanged: (val) {
                          setState(() => _notificationsEnabled = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Save button
                ElevatedButton(
                  onPressed: _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryWellness,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Save Health Profile & Continue',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
