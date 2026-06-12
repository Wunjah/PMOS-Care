import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../providers/presentation/providers/appointment_provider.dart';
import '../../../providers/domain/entities/appointment_entity.dart';

// Figma design tokens (node 68:256)
const _kPrimary = Color(0xFF5152B9);
const _kPrimaryPill = Color(0x338E8FFA);
const _kBarInactive = Color(0x338E8FFA);
const _kDarkText = Color(0xFF191C20);
const _kBodyText = Color(0xFF464552);
const _kMutedText = Color(0xFF777684);
const _kTealDark = Color(0xFF00696A);
const _kTealBg = Color(0x1A45A8A9);
const _kTealBorder = Color(0x3345A8A9);
const _kRose = Color(0xFF844981);
const _kBg = Color(0xFFF8F9FF);
const _kGlass = Color(0xB3FFFFFF);
const _kGlassBorder = Color(0x80FFFFFF);
const _kProgressTrack = Color(0xFFECEEF3);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    String userName = 'User';
    if (authState is AuthAuthenticated) {
      userName = authState.user.displayName;
    }

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final appointmentState = ref.watch(appointmentStateNotifierProvider);
    final upcoming = appointmentState.appointments
        .where((a) => a.dateTime.isAfter(DateTime.now()))
        .toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 68),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _WelcomeSection(greeting: greeting, userName: userName),
                  const SizedBox(height: 24),
                  _BentoGrid(onLogDose: () => context.go('/medication')),
                  const SizedBox(height: 24),
                  _TrackTodaySection(
                    onSymptoms: () => context.go('/symptoms'),
                    onMood: () => context.go('/symptoms'),
                    onNutrition: () => context.go('/diet'),
                    onWeight: () => context.go('/weight'),
                    onViewHistory: () => context.go('/activity'),
                  ),
                  const SizedBox(height: 24),
                  const _ActivityTrendCard(),
                  if (upcoming.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _UpcomingAppointments(
                      appointments: upcoming,
                      onTap: () => context.go('/coach'),
                    ),
                  ],
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ),
          const _TopAppBar(),
          Positioned(
            bottom: 24,
            right: 20,
            child: _FAB(onTap: () => context.go('/symptoms')),
          ),
        ],
      ),
    );
  }
}

// ─── Top App Bar ─────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _kBg.withOpacity(0.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _kPrimary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFE8E9F8),
                    child: Icon(Icons.person, color: _kPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'PMOS Care',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _kPrimary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: _kDarkText,
                      size: 22,
                    ),
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

// ─── Welcome Section ─────────────────────────────────────────────────────────

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.greeting, required this.userName});
  final String greeting;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $userName',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: _kBodyText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'How are you feeling\ntoday?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            height: 1.25,
            letterSpacing: -0.64,
            color: _kDarkText,
          ),
        ),
      ],
    );
  }
}

// ─── Bento Grid ──────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  const _BentoGrid({required this.onLogDose});
  final VoidCallback onLogDose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CyclePhaseCard(),
        const SizedBox(height: 16),
        SizedBox(
          height: 162,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _MedicationCard(onLogDose: onLogDose)),
              const SizedBox(width: 16),
              const Expanded(child: _AiHealthTipCard()),
            ],
          ),
        ),
      ],
    );
  }
}

class _CyclePhaseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGlassBorder),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Purple blur orb (top-right per Figma)
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kPrimary.withOpacity(0.1),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kPrimaryPill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Current Phase',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF221F8A),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Follicular',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w600,
                                fontSize: 24,
                                color: _kPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Day 8 of your cycle',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: _kBodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF8E8FFA),
                            width: 4,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.water_drop,
                            color: Color(0xFF8E8FFA),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Progress bar — 35% (day 8/28 ≈ follicular phase position)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: _kProgressTrack),
                          FractionallySizedBox(
                            widthFactor: 0.35,
                            alignment: Alignment.centerLeft,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _kPrimary,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kPrimary.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
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

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.onLogDose});
  final VoidCallback onLogDose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGlassBorder),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.08),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medication_outlined,
                      color: _kRose, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'NEXT MED',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kRose,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Metformin',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: _kDarkText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '500mg • 9:00 AM',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kBodyText,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onLogDose,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kRose),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Log Dose',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: _kRose,
                    ),
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

class _AiHealthTipCard extends StatelessWidget {
  const _AiHealthTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _kTealBg,
        border: Border.all(color: _kTealBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: _kTealDark, size: 13),
              const SizedBox(width: 4),
              const Text(
                'DAILY TIP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kTealDark,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Text(
              'Focus on fiber today to support insulin sensitivity.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF003839),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.arrow_forward,
                color: _kTealDark.withOpacity(0.8), size: 16),
          ),
        ],
      ),
    );
  }
}

// ─── Track Today ─────────────────────────────────────────────────────────────

class _TrackTodaySection extends StatelessWidget {
  const _TrackTodaySection({
    required this.onSymptoms,
    required this.onMood,
    required this.onNutrition,
    required this.onWeight,
    required this.onViewHistory,
  });

  final VoidCallback onSymptoms;
  final VoidCallback onMood;
  final VoidCallback onNutrition;
  final VoidCallback onWeight;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final items = [
      _TrackItem(
        icon: Icons.monitor_heart_outlined,
        label: 'Symptoms',
        bgColor: const Color(0x1A5152B9),
        color: _kPrimary,
        onTap: onSymptoms,
      ),
      _TrackItem(
        icon: Icons.sentiment_satisfied_alt_outlined,
        label: 'Mood',
        bgColor: const Color(0x33FFB8F8),
        color: const Color(0xFFB85EC5),
        onTap: onMood,
      ),
      _TrackItem(
        icon: Icons.restaurant_outlined,
        label: 'Nutrition',
        bgColor: const Color(0x3345A8A9),
        color: const Color(0xFF45A8A9),
        onTap: onNutrition,
      ),
      _TrackItem(
        icon: Icons.scale_outlined,
        label: 'Weight',
        bgColor: const Color(0x80E1E2E8),
        color: const Color(0xFF5A5A6A),
        onTap: onWeight,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Track Today',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: _kDarkText,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onViewHistory,
              child: const Text(
                'View History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: _kPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, i) => _TrackButton(item: items[i]),
          ),
        ),
      ],
    );
  }
}

class _TrackItem {
  const _TrackItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color color;
  final VoidCallback onTap;
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({required this.item});
  final _TrackItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 112,
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x99FFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kBodyText,
                    letterSpacing: 0.6,
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

// ─── Activity Trend Chart ─────────────────────────────────────────────────────

class _ActivityTrendCard extends StatelessWidget {
  const _ActivityTrendCard();

  static const _barFractions = [0.42, 0.68, 0.53, 0.89, 1.00, 0.47, 0.63];
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _todayIndex = 4; // Friday highlighted in Figma

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGlassBorder),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.05),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Activity Trend',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: _kDarkText,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kTealBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '+12% this week',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kTealDark,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 96,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_barFractions.length, (i) {
                    final isToday = i == _todayIndex;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          heightFactor: _barFractions[i],
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: isToday ? _kPrimary : _kBarInactive,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: _kPrimary.withOpacity(0.3),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_labels.length, (i) {
                  final isToday = i == _todayIndex;
                  return Expanded(
                    child: Text(
                      _labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? _kPrimary : _kMutedText,
                        letterSpacing: 0.6,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming Appointments ───────────────────────────────────────────────────

class _UpcomingAppointments extends StatelessWidget {
  const _UpcomingAppointments({
    required this.appointments,
    required this.onTap,
  });
  final List<AppointmentEntity> appointments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Consultations',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: _kDarkText,
          ),
        ),
        const SizedBox(height: 12),
        ...appointments.map(
          (app) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _kGlass,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGlassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(app.avatarColorValue),
                          radius: 20,
                          child: Text(
                            app.specialistInitials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.specialistName,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _kDarkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${app.consultationType} • '
                                '${DateFormat('MMMd').format(app.dateTime)} at '
                                '${DateFormat('jm').format(app.dateTime)}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: _kMutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: _kMutedText, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _FAB extends StatelessWidget {
  const _FAB({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _kPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
