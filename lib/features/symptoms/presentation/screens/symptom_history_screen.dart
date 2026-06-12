import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/symptom_entity.dart';
import '../providers/symptom_provider.dart';
import '../components/symptom_log_bottom_sheet.dart';

class SymptomHistoryScreen extends ConsumerWidget {
  const SymptomHistoryScreen({super.key});

  void _showSymptomForm(BuildContext context, {SymptomEntity? symptom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SymptomLogBottomSheet(initialSymptom: symptom),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'irritable':
        return '😠';
      case 'anxious':
        return '😰';
      case 'depressed':
        return '😢';
      case 'calm':
      default:
        return '😌';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppTheme.glycemicHigh;
      case 'moderate':
        return AppTheme.glycemicMedium;
      case 'mild':
        return AppTheme.primaryWellness;
      case 'none':
      default:
        return Colors.grey.withAlpha(100);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(symptomStateNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Symptom Tracker',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(symptomStateNotifierProvider.notifier).loadSymptomLogs(),
          ),
        ],
      ),
      body: state.isLoading && state.symptoms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.symptoms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          size: 64,
                          color: AppTheme.primaryWellness.withAlpha(150),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No symptoms logged yet',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Log daily changes to understand your cycle indicators, cravings, skin response, and hormonal patterns.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showSymptomForm(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Log Today\'s Symptoms'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: state.symptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = state.symptoms[index];
                    final dateStr =
                        '${symptom.timestamp.year}-${symptom.timestamp.month.toString().padLeft(2, '0')}-${symptom.timestamp.day.toString().padLeft(2, '0')}';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withAlpha(50)),
                      ),
                      child: InkWell(
                        onTap: () => _showSymptomForm(context, symptom: symptom),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Date, Edit, Delete
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () => _showSymptomForm(context, symptom: symptom),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.glycemicHigh),
                                        onPressed: () => _confirmDelete(context, ref, symptom.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 8),
                              const SizedBox(height: 8),

                              // Mood & Fatigue Overview
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryWellness.withAlpha(30),
                                    radius: 20,
                                    child: Text(
                                      _getMoodEmoji(symptom.mood),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mood: ${symptom.mood.toUpperCase()}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(
                                            'Fatigue: ${symptom.fatigueLevel}/5',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Pelvic Pain: ${symptom.pelvicPain}/5',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Skin & Hair Indicators (Androgens)
                              if (symptom.acneSeverity != 'none' ||
                                  symptom.alopeciaSeverity != 'none' ||
                                  symptom.ferrimanGallweyScore != null) ...[
                                const Text(
                                  'Skin & Androgens:',
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (symptom.acneSeverity != 'none')
                                      _buildStatusBadge(
                                        'Acne: ${symptom.acneSeverity}',
                                        _getSeverityColor(symptom.acneSeverity),
                                      ),
                                    if (symptom.alopeciaSeverity != 'none')
                                      _buildStatusBadge(
                                        'Thinning: ${symptom.alopeciaSeverity}',
                                        _getSeverityColor(symptom.alopeciaSeverity),
                                      ),
                                    if (symptom.ferrimanGallweyScore != null)
                                      _buildStatusBadge(
                                        'Hirsutism FG: ${symptom.ferrimanGallweyScore}',
                                        symptom.ferrimanGallweyScore! >= 16
                                            ? AppTheme.glycemicHigh
                                            : (symptom.ferrimanGallweyScore! >= 8
                                                ? AppTheme.glycemicMedium
                                                : AppTheme.glycemicLow),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Metabolic & Insulin Resistance Markers
                              if (symptom.bloating ||
                                  symptom.acanthosisNigricans ||
                                  symptom.skinTags ||
                                  symptom.cravings.isNotEmpty) ...[
                                const Text(
                                  'Metabolic & Insulin:',
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (symptom.bloating)
                                      _buildStatusBadge('Bloating', AppTheme.accentMenstrual),
                                    if (symptom.acanthosisNigricans)
                                      _buildStatusBadge('Acanthosis Nigricans', AppTheme.primaryWellness),
                                    if (symptom.skinTags)
                                      _buildStatusBadge('Skin Tags', AppTheme.primaryWellness),
                                    ...symptom.cravings.map(
                                      (craving) => _buildStatusBadge(
                                        'Craving: $craving',
                                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                        textColor: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryWellness,
        foregroundColor: Colors.white,
        onPressed: () => _showSymptomForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor ?? color,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this symptom log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(symptomStateNotifierProvider.notifier).removeSymptomLog(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.glycemicHigh)),
          ),
        ],
      ),
    );
  }
}

