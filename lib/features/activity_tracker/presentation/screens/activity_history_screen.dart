import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/activity_provider.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  double _estimateCalories(String type, int duration) {
    switch (type) {
      case 'running':
        return duration * 9.0;
      case 'home_workout':
        return duration * 6.0;
      case 'gym':
        return duration * 7.5;
      case 'walking':
      default:
        return duration * 4.5;
    }
  }

  void _showAddActivityDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    String selectedType = 'walking';
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final List<Map<String, String>> types = [
      {'value': 'walking', 'label': 'Walking'},
      {'value': 'running', 'label': 'Running'},
      {'value': 'home_workout', 'label': 'Home Workout'},
      {'value': 'gym', 'label': 'Gym Session'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Log Activity',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Activity Type',
                          border: OutlineInputBorder(),
                        ),
                        items: types.map((t) {
                          return DropdownMenuItem<String>(
                            value: t['value'],
                            child: Text(t['label']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedType = val;
                              // Update calories estimation if duration is entered
                              final dur = int.tryParse(durationController.text);
                              if (dur != null) {
                                caloriesController.text = _estimateCalories(val, dur).toStringAsFixed(0);
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 30',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Duration is required';
                          final numVal = int.tryParse(val);
                          if (numVal == null || numVal <= 0) return 'Enter a valid positive number';
                          return null;
                        },
                        onChanged: (val) {
                          final dur = int.tryParse(val);
                          if (dur != null) {
                            setState(() {
                              caloriesController.text = _estimateCalories(selectedType, dur).toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: caloriesController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Calories Burned (kcal)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 150',
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Calories is required';
                          final numVal = double.tryParse(val);
                          if (numVal == null || numVal < 0) return 'Enter a valid positive number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(100, 40)),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final dur = int.parse(durationController.text);
                      final cal = double.parse(caloriesController.text);
                      await ref.read(activityStateNotifierProvider.notifier).addActivity(
                            type: selectedType,
                            duration: dur,
                            calories: cal,
                            date: selectedDate,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Activity logged successfully!'),
                            backgroundColor: AppTheme.glycemicLow,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatActivityName(String raw) {
    switch (raw) {
      case 'home_workout':
        return 'Home Workout';
      case 'gym':
        return 'Gym Workout';
      case 'running':
        return 'Running';
      case 'walking':
      default:
        return 'Walking';
    }
  }

  IconData _getActivityIcon(String raw) {
    switch (raw) {
      case 'running':
        return Icons.directions_run;
      case 'home_workout':
        return Icons.fitness_center;
      case 'gym':
        return Icons.sports_gymnastics;
      case 'walking':
      default:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Activity Tracker',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(activityStateNotifierProvider.notifier).loadActivities(),
          ),
        ],
      ),
      body: state.isLoading && state.activities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Activity Summary Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: AppTheme.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'Active Streak',
                                style: TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${state.currentStreak} Days',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryWellness,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.withAlpha(100)),
                          Column(
                            children: [
                              const Text(
                                'Total Burned',
                                style: TextStyle(fontFamily: 'Inter', color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${state.totalCaloriesBurned.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryWellness,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Activity Logs History
                Expanded(
                  child: state.activities.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_run_outlined,
                                  size: 64,
                                  color: AppTheme.primaryWellness.withAlpha(150),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No workouts logged yet',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Log walking, running, home/gym workouts to boost insulin sensitivity and manage hormone levels.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddActivityDialog(context, ref),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Log First Workout'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: state.activities.length,
                          itemBuilder: (context, index) {
                            final log = state.activities[index];
                            final dateStr =
                                '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.withAlpha(50)),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryWellness.withAlpha(30),
                                  child: Icon(_getActivityIcon(log.activityType), color: AppTheme.primaryWellness),
                                ),
                                title: Text(
                                  _formatActivityName(log.activityType),
                                  style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Duration: ${log.durationMinutes} mins | Burned: ${log.caloriesBurned.toStringAsFixed(0)} kcal | $dateStr',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.glycemicHigh),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Log'),
                                        content: const Text('Are you sure you want to delete this workout log?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ref.read(activityStateNotifierProvider.notifier).removeActivity(log.id);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: AppTheme.glycemicHigh)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryWellness,
        foregroundColor: Colors.white,
        onPressed: () => _showAddActivityDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
