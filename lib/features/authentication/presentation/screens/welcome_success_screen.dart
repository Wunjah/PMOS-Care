import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeSuccessScreen extends StatelessWidget {
  const WelcomeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Animated Circular Checkmark Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1), // Soft teal circle
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.brandActive.withOpacity(0.3), width: 4),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Color(0xFF00796B), // Deep teal checkmark
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Title Header
              const Text(
                'Welcome to PMOS Care',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Your account has been successfully created. We’re here to support you on every step of your health journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // HIPAA compliance security card
              Card(
                color: AppTheme.primaryLight.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.primaryWellness.withOpacity(0.1)),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_person_outlined, color: AppTheme.primaryWellness, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Security Guaranteed',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your Protected Health Information (PHI) is encrypted and stored according to strict HIPAA compliance standards.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),

              // Continue to Health Profile Button
              ElevatedButton.icon(
                onPressed: () => context.go('/health-profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryWellness,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Text(
                  'Continue to Health Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                label: const Icon(Icons.arrow_forward),
              ),
              const SizedBox(height: 16),

              // Support Text
              GestureDetector(
                onTap: () async {
                  final uri = Uri(
                    scheme: 'mailto',
                    path: 'support@pmoscare.org',
                    queryParameters: {'subject': 'PMOS Care App Support'},
                  );
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                child: const Text(
                  'Need help? Contact Support',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
