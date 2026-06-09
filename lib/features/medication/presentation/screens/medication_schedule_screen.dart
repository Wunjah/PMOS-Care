import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/medication_entity.dart';
import '../providers/medication_provider.dart';

class MedicationScheduleScreen extends ConsumerWidget {
  const MedicationScheduleScreen({super.key});

  void _showAddMedDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    String selectedTiming = 'breakfast';

    final List<String> timings = ['breakfast', 'lunch', 'dinner', 'bedtime'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Add Medication',
                style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. Metformin',
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. 500mg (1 tablet)',
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Dosage is required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedTiming,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Timing',
                        border: OutlineInputBorder(),
                      ),
                      items: timings.map((t) {
                        return DropdownMenuItem<String>(
                          value: t,
                          child: Text(t.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedTiming = val);
                        }
                      },
                    ),
                  ],
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
                      await ref.read(medicationStateNotifierProvider.notifier).addMedication(
                            name: nameController.text,
                            dosage: dosageController.text,
                            timing: selectedTiming,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Medication added successfully!'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationStateNotifierProvider);

    final totalDoses = state.medications.length;
    final completedDoses = state.medications.where((e) => e.isTakenToday).length;

    // Grouping
    final breakfastMeds = state.medications.where((e) => e.timing == 'breakfast').toList();
    final lunchMeds = state.medications.where((e) => e.timing == 'lunch').toList();
    final dinnerMeds = state.medications.where((e) => e.timing == 'dinner').toList();
    final bedtimeMeds = state.medications.where((e) => e.timing == 'bedtime').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medication Schedule',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(medicationStateNotifierProvider.notifier).loadMedications(),
          ),
        ],
      ),
      body: state.isLoading && state.medications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Adherence Progress Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: AppTheme.primaryLight,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircularProgressIndicator(
                            value: totalDoses == 0 ? 0.0 : completedDoses / totalDoses,
                            color: AppTheme.primaryWellness,
                            backgroundColor: Colors.grey.shade300,
                            strokeWidth: 6,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\'s Adherence',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryWellness,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalDoses == 0
                                      ? 'No medications scheduled today.'
                                      : '$completedDoses of $totalDoses doses taken today.',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Schedule list
                Expanded(
                  child: state.medications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 64,
                                  color: AppTheme.primaryWellness.withAlpha(150),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No medications scheduled',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Schedule clinical treatments like Metformin, Inositol, or Spironolactone to manage symptoms.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddMedDialog(context, ref),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Medication'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(200, 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 80),
                          children: [
                            if (breakfastMeds.isNotEmpty)
                              _buildTimingSection(context, ref, 'Breakfast Reminders', breakfastMeds),
                            if (lunchMeds.isNotEmpty)
                              _buildTimingSection(context, ref, 'Lunch Reminders', lunchMeds),
                            if (dinnerMeds.isNotEmpty)
                              _buildTimingSection(context, ref, 'Supper/Dinner Reminders', dinnerMeds),
                            if (bedtimeMeds.isNotEmpty)
                              _buildTimingSection(context, ref, 'Bedtime Reminders', bedtimeMeds),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryWellness,
        foregroundColor: Colors.white,
        onPressed: () => _showAddMedDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTimingSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<MedicationEntity> meds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryWellness,
            ),
          ),
        ),
        ...meds.map((med) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withAlpha(50)),
            ),
            child: CheckboxListTile(
              title: Text(
                med.name,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  decoration: med.isTakenToday ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                'Dosage: ${med.dosage}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
              ),
              value: med.isTakenToday,
              activeColor: AppTheme.primaryWellness,
              onChanged: (val) {
                if (val != null) {
                  ref.read(medicationStateNotifierProvider.notifier).toggleTaken(med.id, val);
                }
              },
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.glycemicHigh),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Medication'),
                      content: const Text('Are you sure you want to remove this medication from your schedule?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(medicationStateNotifierProvider.notifier).removeMedication(med.id);
                            Navigator.pop(context);
                          },
                          child: const Text('Remove', style: TextStyle(color: AppTheme.glycemicHigh)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
