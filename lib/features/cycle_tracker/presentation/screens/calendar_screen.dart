import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/cycle_provider.dart';
import '../../domain/entities/cycle_entity.dart';
import '../components/calendar_widget.dart';
import '../components/cycle_charts.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  
  void _showLogCycleSheet(BuildContext context, DateTime selectedDate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _LogCycleForm(
          initialDate: selectedDate,
          onSubmit: (startDate, endDate, flow, pain, symptoms) {
            ref.read(cycleStateNotifierProvider.notifier).addCycleLog(
              startDate: startDate,
              endDate: endDate,
              flowIntensity: flow,
              painLevel: pain,
              symptoms: symptoms,
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycleState = ref.watch(cycleStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cycle Tracker',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(cycleStateNotifierProvider.notifier).loadCycleLogs(),
          ),
        ],
      ),
      body: cycleState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPredictionCard(cycleState.predictedNextDate),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CalendarWidget(
                        cycles: cycleState.cycles,
                        predictedNextDate: cycleState.predictedNextDate,
                        onDaySelected: (date) => _showLogCycleSheet(context, date),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CycleCharts(cycles: cycleState.cycles),
                    ),
                    const SizedBox(height: 16),

                    _buildHistoryList(cycleState.cycles),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryWellness,
        foregroundColor: Colors.white,
        onPressed: () => _showLogCycleSheet(context, DateTime.now()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPredictionCard(DateTime? nextDate) {
    if (nextDate == null) return const SizedBox.shrink();

    final difference = nextDate.difference(DateTime.now()).inDays;
    String predictionText;
    if (difference == 0) {
      predictionText = 'Your period is predicted to start today!';
    } else if (difference < 0) {
      predictionText = 'Your period is late by ${difference.abs()} days (Common in PMOS)';
    } else {
      predictionText = 'Next period predicted in $difference days (${_formatDateShort(nextDate)})';
    }

    return Card(
      color: AppTheme.accentRoseWash,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.accentMenstrual, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.accentMenstrual),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                predictionText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentMenstrual,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<CycleEntity> cycles) {
    final userLogs = cycles.where((e) => !e.isPredicted).toList();
    if (userLogs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Past Logs History',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userLogs.length,
            itemBuilder: (context, index) {
              final log = userLogs[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.accentRoseWash,
                    child: Icon(Icons.water_drop, color: AppTheme.accentMenstrual),
                  ),
                  title: Text(
                    'Started ${_formatDate(log.startDate)}',
                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                  ),
                  subtitle: Builder(
                    builder: (context) {
                      final moodItem = log.symptoms.firstWhere(
                        (s) => s.startsWith('mood:'),
                        orElse: () => '',
                      );
                      final moodStr = moodItem.isNotEmpty ? moodItem.replaceFirst('mood:', '') : 'Normal';
                      return Text(
                        'Mood: $moodStr • Flow: ${log.flowIntensity.name.toUpperCase()} • Pain: ${log.painLevel}/5',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      );
                    }
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => ref.read(cycleStateNotifierProvider.notifier).removeCycleLog(log.id),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _LogCycleForm extends StatefulWidget {
  final DateTime initialDate;
  final Function(
    DateTime startDate,
    DateTime? endDate,
    FlowIntensity flowIntensity,
    int painLevel,
    List<String> symptoms,
  ) onSubmit;

  const _LogCycleForm({
    required this.initialDate,
    required this.onSubmit,
  });

  @override
  State<_LogCycleForm> createState() => _LogCycleFormState();
}

class _LogCycleFormState extends State<_LogCycleForm> {
  late DateTime _startDate;
  DateTime? _endDate;
  FlowIntensity _flowIntensity = FlowIntensity.medium;
  int _painLevel = 2;
  final List<String> _selectedSymptoms = [];
  String _selectedMood = '😊 Happy';

  final List<String> _moodTags = ['😊 Happy', '😔 Sad', '😠 Irritated', '😰 Anxious', '⚡ Energetic', '😴 Tired'];
  final List<String> _symptomTags = ['Cramps', 'Acne', 'Bloating', 'Headache', 'Backache', 'Mood Swings', 'Fatigue'];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Menstrual Period',
              style: TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryWellness),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime.now(),
                          );
                          if (selected != null) {
                            setState(() {
                              _startDate = selected;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Date (Optional)', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_endDate == null ? 'Ongoing' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                        onPressed: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _startDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now(),
                          );
                          if (selected != null) {
                            setState(() {
                              _endDate = selected;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Flow Intensity', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: FlowIntensity.values.map((intensity) {
                final isSelected = _flowIntensity == intensity;
                return ChoiceChip(
                  label: Text(intensity.name.toUpperCase()),
                  selected: isSelected,
                  selectedColor: AppTheme.accentRoseWash,
                  checkmarkColor: AppTheme.accentMenstrual,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _flowIntensity = intensity;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pain Level', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                Text('$_painLevel/5', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentMenstrual)),
              ],
            ),
            Slider(
              value: _painLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: AppTheme.accentMenstrual,
              onChanged: (val) {
                setState(() {
                  _painLevel = val.round();
                });
              },
            ),
            const SizedBox(height: 16),

            const Text('Your Mood', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodTags.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryLight,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedMood = mood;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('Symptoms Experienced', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptomTags.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryLight,
                  checkmarkColor: AppTheme.primaryWellness,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                final loggedSymptoms = [..._selectedSymptoms, 'mood:$_selectedMood'];
                widget.onSubmit(_startDate, _endDate, _flowIntensity, _painLevel, loggedSymptoms);
              },
              child: const Text('Save Period Log'),
            ),
          ],
        ),
      ),
    );
  }
}
