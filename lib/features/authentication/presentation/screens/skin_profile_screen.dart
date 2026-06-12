import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SkinProfileScreen extends ConsumerStatefulWidget {
  const SkinProfileScreen({super.key});

  @override
  ConsumerState<SkinProfileScreen> createState() => _SkinProfileScreenState();
}

class _SkinProfileScreenState extends ConsumerState<SkinProfileScreen> {
  String _selectedSeverity = 'Moderate';
  final List<String> _affectedAreas = ['Jawline', 'Cheeks'];

  final List<Map<String, dynamic>> _severityOptions = [
    {
      'id': 'None',
      'title': 'None',
      'subtitle': 'Clear skin',
      'icon': Icons.face_retouching_natural,
      'color': Colors.blue,
    },
    {
      'id': 'Mild',
      'title': 'Mild',
      'subtitle': 'Few bumps',
      'icon': Icons.sentiment_neutral,
      'color': Colors.green,
    },
    {
      'id': 'Moderate',
      'title': 'Moderate',
      'subtitle': 'Frequent breakouts',
      'icon': Icons.sentiment_dissatisfied,
      'color': AppTheme.primaryWellness,
    },
    {
      'id': 'Severe',
      'title': 'Severe',
      'subtitle': 'Inflamed/Cystic',
      'icon': Icons.mood_bad,
      'color': AppTheme.accentMenstrual,
    },
  ];

  final List<String> _areaOptions = [
    'Jawline',
    'Cheeks',
    'Chin',
    'Forehead',
    'Back',
    'Chest',
  ];

  void _toggleArea(String area) {
    setState(() {
      if (_affectedAreas.contains(area)) {
        _affectedAreas.remove(area);
      } else {
        _affectedAreas.add(area);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => context.go('/welcome-success'),
        ),
        title: const Text(
          'Skin Profile',
          style: TextStyle(fontFamily: 'Outfit', color: AppTheme.textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Step progress indicator bar
          Container(
            width: 80,
            height: 6,
            margin: const EdgeInsets.only(right: 16),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryWellness),
              ),
            ),
          ),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Current Skin State',
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
                'Help our clinical team tailor your hormonal skin recovery plan by documenting your current concerns.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Overall Severity Header
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1. Overall Severity',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryWellness),
                  ),
                  Text(
                    'REQUIRED',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Severity Grid Layout (2x2)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: _severityOptions.length,
                itemBuilder: (context, index) {
                  final option = _severityOptions[index];
                  final isSelected = _selectedSeverity == option['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSeverity = option['id']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryWellness : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option['icon'] as IconData,
                              size: 40,
                              color: isSelected ? AppTheme.primaryWellness : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              option['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primaryWellness : AppTheme.textDark,
                              ),
                            ),
                            Text(
                              option['subtitle'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Affected Areas Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '2. Affected Areas',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryWellness),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_affectedAreas.length == _areaOptions.length) {
                          _affectedAreas.clear();
                        } else {
                          _affectedAreas.clear();
                          _affectedAreas.addAll(_areaOptions);
                        }
                      });
                    },
                    child: const Text(
                      'SELECT ALL',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryWellness),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Area Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _areaOptions.map((area) {
                  final isSelected = _affectedAreas.contains(area);
                  return GestureDetector(
                    onTap: () => _toggleArea(area),
                    child: Chip(
                      label: Text(
                        area,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryWellness : Colors.grey.shade700,
                        ),
                      ),
                      backgroundColor: isSelected ? AppTheme.primaryLight : Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryWellness.withOpacity(0.5) : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Did you know? informational box
              Card(
                color: const Color(0xFFECEFF1).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryWellness, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Did you know?',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Acne along the jawline and chin is often a primary indicator of hormonal shifts related to insulin and androgen sensitivity.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bottom action buttons: Skip / Continue
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/connected-apps'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(authStateNotifierProvider.notifier).saveSkinProfile(
                          severity: _selectedSeverity,
                          affectedAreas: List.from(_affectedAreas),
                        );
                        if (context.mounted) context.go('/connected-apps');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryWellness,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
