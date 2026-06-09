import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ConnectedAppsScreen extends ConsumerStatefulWidget {
  const ConnectedAppsScreen({super.key});

  @override
  ConsumerState<ConnectedAppsScreen> createState() => _ConnectedAppsScreenState();
}

class _ConnectedAppsScreenState extends ConsumerState<ConnectedAppsScreen> {
  bool _syncHeartRate = true;
  bool _syncDailySteps = true;
  bool _syncBloodGlucose = false;
  bool _googleFitConnected = false;

  void _finishOnboarding() {
    ref.read(authStateNotifierProvider.notifier).completeOnboarding();
    context.go('/home');
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
          onPressed: () => context.go('/skin-profile'),
        ),
        title: const Text(
          'Connected Apps',
          style: TextStyle(fontFamily: 'Outfit', color: AppTheme.textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sync Health Data',
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
                'Sync your health data automatically from your favorite devices and apps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Apple Health Main Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apple Health',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Connected • Last sync: 2m ago',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'MP6Pge',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryWellness,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Heart Rate Switch
                      SwitchListTile(
                        value: _syncHeartRate,
                        activeColor: AppTheme.primaryWellness,
                        title: const Row(
                          children: [
                            Icon(Icons.favorite_border, color: AppTheme.primaryWellness),
                            SizedBox(width: 12),
                            Text('Heart Rate', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                          ],
                        ),
                        onChanged: (val) => setState(() => _syncHeartRate = val),
                      ),

                      // Daily Steps Switch
                      SwitchListTile(
                        value: _syncDailySteps,
                        activeColor: AppTheme.primaryWellness,
                        title: const Row(
                          children: [
                            Icon(Icons.directions_run, color: AppTheme.primaryWellness),
                            SizedBox(width: 12),
                            Text('Daily Steps', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                          ],
                        ),
                        onChanged: (val) => setState(() => _syncDailySteps = val),
                      ),

                      // Blood Glucose Switch
                      SwitchListTile(
                        value: _syncBloodGlucose,
                        activeColor: AppTheme.primaryWellness,
                        title: const Row(
                          children: [
                            Icon(Icons.opacity, color: AppTheme.primaryWellness),
                            SizedBox(width: 12),
                            Text('Blood Glucose', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                          ],
                        ),
                        onChanged: (val) => setState(() => _syncBloodGlucose = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Other Devices Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Text(
                  'OTHER DEVICES',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Google Fit Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitbit, color: Colors.orange),
                  ),
                  title: const Text(
                    'Google Fit',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _googleFitConnected ? 'Connected' : 'Not connected',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                  ),
                  trailing: _googleFitConnected
                      ? const Text('Connected', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))
                      : OutlinedButton(
                          onPressed: () => setState(() => _googleFitConnected = true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryWellness),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Connect', style: TextStyle(color: AppTheme.primaryWellness, fontSize: 12)),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Withings Scale Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.monitor_weight_outlined, color: Colors.blue),
                  ),
                  title: const Text(
                    'Withings Scale',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Connected • Last sync: Yesterday',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // Privacy card
              Card(
                color: AppTheme.primaryLight.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppTheme.primaryWellness.withOpacity(0.1)),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, color: AppTheme.primaryWellness, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Data privacy is our priority. Your medical-grade data is encrypted and only used to provide personalized health insights. You can revoke access at any time.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Complete Profile Button
              ElevatedButton(
                onPressed: _finishOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryWellness,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Complete Profile & Onboarding',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
