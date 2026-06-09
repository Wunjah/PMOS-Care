import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../localization/translations.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/signup_screen.dart';
import '../../features/authentication/presentation/screens/otp_verification_screen.dart';
import '../../features/authentication/presentation/screens/welcome_success_screen.dart';
import '../../features/authentication/presentation/screens/health_profile_setup_screen.dart';
import '../../features/authentication/presentation/screens/biometric_lock_screen.dart';
import '../../features/authentication/presentation/screens/skin_profile_screen.dart';
import '../../features/authentication/presentation/screens/connected_apps_screen.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/cycle_tracker/presentation/screens/calendar_screen.dart';
import '../../features/symptoms/presentation/screens/symptom_history_screen.dart';
import '../../features/weight_tracker/presentation/screens/weight_history_screen.dart';
import '../../features/activity_tracker/presentation/screens/activity_history_screen.dart';
import '../../features/medication/presentation/screens/medication_schedule_screen.dart';
import '../../features/diet/presentation/screens/diet_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/education/presentation/screens/education_hub_screen.dart';
import '../../features/providers/presentation/screens/specialist_directory_screen.dart';
import '../../features/reports/presentation/screens/reports_hub_screen.dart';
import '../theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/welcome-success',
        builder: (context, state) => const WelcomeSuccessScreen(),
      ),
      GoRoute(
        path: '/health-profile',
        builder: (context, state) => const HealthProfileSetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const BiometricLockScreen(),
      ),
      GoRoute(
        path: '/skin-profile',
        builder: (context, state) => const SkinProfileScreen(),
      ),
      GoRoute(
        path: '/connected-apps',
        builder: (context, state) => const ConnectedAppsScreen(),
      ),
      GoRoute(
        path: '/symptoms',
        builder: (context, state) => const SymptomHistoryScreen(),
      ),
      GoRoute(
        path: '/weight',
        builder: (context, state) => const WeightHistoryScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityHistoryScreen(),
      ),
      GoRoute(
        path: '/medication',
        builder: (context, state) => const MedicationScheduleScreen(),
      ),
      GoRoute(
        path: '/education',
        builder: (context, state) => const EducationHubScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/diet',
            builder: (context, state) => const DietScreen(),
          ),
          GoRoute(
            path: '/coach',
            builder: (context, state) => const SpecialistDirectoryScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsHubScreen(),
          ),
        ],
      ),
    ],
  );
});

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final authState = ref.read(authStateNotifierProvider);
      if (authState is AuthAuthenticated) {
        if (authState.user.biometricLockEnabled) {
          context.go('/lock');
        } else if (authState.user.isOnboardingCompleted) {
          context.go('/home');
        } else {
          context.go('/welcome-success');
        }
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, size: 64, color: AppTheme.primaryWellness),
            SizedBox(height: 16),
            Text(
              'PMOS Care',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    if (location.startsWith('/calendar')) currentIndex = 1;
    if (location.startsWith('/diet')) currentIndex = 2;
    if (location.startsWith('/coach')) currentIndex = 3;
    if (location.startsWith('/reports')) currentIndex = 4;

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/calendar');
              break;
            case 2:
              context.go('/diet');
              break;
            case 3:
              context.go('/coach');
              break;
            case 4:
              context.go('/reports');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: context.translate('nav_home')),
          BottomNavigationBarItem(icon: const Icon(Icons.calendar_month_outlined), label: context.translate('nav_calendar')),
          BottomNavigationBarItem(icon: const Icon(Icons.restaurant_outlined), label: context.translate('nav_diet')),
          BottomNavigationBarItem(icon: const Icon(Icons.people_outline), label: context.translate('nav_coach')),
          BottomNavigationBarItem(icon: const Icon(Icons.analytics_outlined), label: context.translate('nav_reports')),
        ],
      ),
    );
  }
}

