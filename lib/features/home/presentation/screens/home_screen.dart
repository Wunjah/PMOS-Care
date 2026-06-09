import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../providers/presentation/providers/appointment_provider.dart';
import '../../../providers/domain/entities/appointment_entity.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Checklists state
  bool _breakfastTicked = false;
  bool _lunchTicked = false;
  bool _supperTicked = false;
  bool _sportsTicked = false;
  bool _medsTicked = false;

  @override
  Widget build(BuildContext context) {
    // Get username from provider
    final authState = ref.watch(authStateNotifierProvider);
    String userName = 'User';
    if (authState is AuthAuthenticated) {
      userName = authState.user.displayName;
    }

    final appointmentState = ref.watch(appointmentStateNotifierProvider);
    final upcomingAppointments = appointmentState.appointments.where((app) {
      return app.dateTime.isAfter(DateTime.now());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryWellness,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              background: Container(color: AppTheme.primaryWellness),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authStateNotifierProvider.notifier).logout(),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cycle Status Quick Info Card
                  _buildCycleQuickCard(),
                  const SizedBox(height: 24),

                  // Reminders Section
                  const Text(
                    'Daily Reminders',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRemindersPanel(),
                  const SizedBox(height: 24),

                  // Upcoming Consultations
                  _buildUpcomingAppointments(upcomingAppointments),

                  // Daily Habit Checklist (Meals, Sports)
                  const Text(
                    'Daily Checklist',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildChecklistPanel(),
                  const SizedBox(height: 24),

                  // Quick Action Menu Buttons
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionsGrid(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments(List<AppointmentEntity> appointments) {
    if (appointments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Consultations',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        ...appointments.map((app) {
          final timeStr = DateFormat('jm').format(app.dateTime);
          final dateStr = DateFormat('yMMMMd').format(app.dateTime);

          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(app.avatarColorValue),
                child: Text(
                  app.specialistInitials,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              title: Text(
                app.specialistName,
                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '${app.consultationType} | $dateStr at $timeStr',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () => context.go('/coach'),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCycleQuickCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.accentRoseWash,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop, color: AppTheme.accentMenstrual, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menstrual Cycle Status',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log your period to get accurate predictions.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryWellness, size: 28),
              onPressed: () => context.go('/calendar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersPanel() {
    return Card(
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
            _buildReminderRow(
              Icons.breakfast_dining_outlined,
              'Breakfast Reminder',
              'Take at 8:00 AM',
              onTap: () => context.go('/diet'),
            ),
            const Divider(),
            _buildReminderRow(
              Icons.restaurant_menu_outlined,
              'Lunch/Supper Reminder',
              'Take lunch at 1:00 PM, supper at 7:00 PM',
              onTap: () => context.go('/diet'),
            ),
            const Divider(),
            _buildReminderRow(
              Icons.medication_outlined,
              'Medication Alert',
              'Take Metformin/Spironolactone after lunch',
              onTap: () => context.go('/medication'),
            ),
            const Divider(),
            _buildReminderRow(
              Icons.sports_soccer,
              'Sports Activity Reminder',
              'Recommended: 30m aerobic exercise',
              onTap: () => context.go('/activity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderRow(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryWellness),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistPanel() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CheckboxListTile(
              value: _breakfastTicked,
              activeColor: AppTheme.primaryWellness,
              title: const Text('Eat Breakfast', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onChanged: (val) => setState(() => _breakfastTicked = val ?? false),
            ),
            CheckboxListTile(
              value: _lunchTicked,
              activeColor: AppTheme.primaryWellness,
              title: const Text('Eat Lunch', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onChanged: (val) => setState(() => _lunchTicked = val ?? false),
            ),
            CheckboxListTile(
              value: _supperTicked,
              activeColor: AppTheme.primaryWellness,
              title: const Text('Eat Supper', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onChanged: (val) => setState(() => _supperTicked = val ?? false),
            ),
            CheckboxListTile(
              value: _sportsTicked,
              activeColor: AppTheme.primaryWellness,
              title: const Text('Do Sports / Exercises', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onChanged: (val) => setState(() => _sportsTicked = val ?? false),
            ),
            CheckboxListTile(
              value: _medsTicked,
              activeColor: AppTheme.primaryWellness,
              title: const Text('Take Medication', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              onChanged: (val) => setState(() => _medsTicked = val ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Diet Guide',
        'desc': 'Interactive Meal Prep',
        'icon': Icons.restaurant,
        'route': '/diet',
        'color': Colors.amber,
      },
      {
        'title': 'Cycle Log',
        'desc': 'Track menstruation',
        'icon': Icons.calendar_month,
        'route': '/calendar',
        'color': Colors.red,
      },
      {
        'title': 'Symptom Logger',
        'desc': 'Acne, hirsutism, pain',
        'icon': Icons.monitor_heart_outlined,
        'route': '/symptoms',
        'color': AppTheme.primaryWellness,
      },
      {
        'title': 'Weight & Waist',
        'desc': 'Log metabolic metrics',
        'icon': Icons.scale_outlined,
        'route': '/weight',
        'color': Colors.blue,
      },
      {
        'title': 'Activity Tracker',
        'desc': 'Log cardio & workouts',
        'icon': Icons.directions_run_outlined,
        'route': '/activity',
        'color': Colors.orange,
      },
      {
        'title': 'Find Specialist',
        'desc': 'Ob-Gyn Booking',
        'icon': Icons.medical_services_outlined,
        'route': '/coach',
        'color': Colors.teal,
      },
      {
        'title': 'Education',
        'desc': 'PMOS Hub & Videos',
        'icon': Icons.menu_book,
        'route': '/education',
        'color': Colors.green,
      },
      {
        'title': 'Lab Reports',
        'desc': 'Download PDF/CSV',
        'icon': Icons.picture_as_pdf,
        'route': '/reports',
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final act = actions[index];
        return GestureDetector(
          onTap: () => context.go(act['route'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(act['icon'] as IconData, color: act['color'] as Color, size: 28),
                const SizedBox(height: 8),
                Text(
                  act['title'] as String,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  act['desc'] as String,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
