import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/symptom_entity.dart';
import '../providers/symptom_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SymptomLogBottomSheet extends ConsumerStatefulWidget {
  final SymptomEntity? initialSymptom; // If editing

  const SymptomLogBottomSheet({super.key, this.initialSymptom});

  @override
  ConsumerState<SymptomLogBottomSheet> createState() => _SymptomLogBottomSheetState();
}

class _SymptomLogBottomSheetState extends ConsumerState<SymptomLogBottomSheet> {
  late DateTime _selectedDate;
  int? _fgScore;
  late String _acneSeverity;
  late String _alopeciaSeverity;
  late int _fatigueLevel;
  late String _mood;
  late List<String> _cravings;
  late bool _bloating;
  late int _pelvicPain;
  late bool _acanthosisNigricans;
  late bool _skinTags;

  final List<String> _acneOptions = ['none', 'mild', 'moderate', 'severe'];
  final List<String> _alopeciaOptions = ['none', 'mild', 'moderate', 'severe'];
  final List<String> _moodOptions = ['calm', 'happy', 'irritable', 'anxious', 'depressed'];
  final List<String> _cravingOptions = ['Sugar', 'Carbs', 'Salt', 'Chocolate', 'Fried Foods', 'Late Night'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialSymptom;
    _selectedDate = init?.timestamp ?? DateTime.now();
    _fgScore = init?.ferrimanGallweyScore;
    _acneSeverity = init?.acneSeverity ?? 'none';
    _alopeciaSeverity = init?.alopeciaSeverity ?? 'none';
    _fatigueLevel = init?.fatigueLevel ?? 1;
    _mood = init?.mood ?? 'calm';
    _cravings = List<String>.from(init?.cravings ?? []);
    _bloating = init?.bloating ?? false;
    _pelvicPain = init?.pelvicPain ?? 1;
    _acanthosisNigricans = init?.acanthosisNigricans ?? false;
    _skinTags = init?.skinTags ?? false;
  }

  String _getFGInterpretation(int score) {
    if (score == 0) return 'None';
    if (score < 8) return 'Mild Hirsutism ($score)';
    if (score < 15) return 'Moderate Hirsutism ($score)';
    return 'Severe Hirsutism ($score)';
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryWellness, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryWellness,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialSymptom == null ? 'Log Symptoms' : 'Edit Symptoms',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Date Picker
                _buildCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Logging Date',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 90)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // General Section
                _buildSectionTitle('General Well-being', Icons.healing_outlined),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mood', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                          Text(
                            _mood.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryWellness,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _moodOptions.map((m) {
                          final selected = _mood == m;
                          return ChoiceChip(
                            label: Text(m),
                            selected: selected,
                            selectedColor: AppTheme.primaryWellness.withAlpha(40),
                            checkmarkColor: AppTheme.primaryWellness,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: selected ? AppTheme.primaryWellness : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _mood = m);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Fatigue Level (1 = Energetic, 5 = Exhausted)',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      Slider(
                        value: _fatigueLevel.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: AppTheme.primaryWellness,
                        label: _fatigueLevel.toString(),
                        onChanged: (val) {
                          setState(() => _fatigueLevel = val.toInt());
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Pelvic Pain (1 = None, 5 = Severe)',
                          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      Slider(
                        value: _pelvicPain.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: AppTheme.accentMenstrual,
                        label: _pelvicPain.toString(),
                        onChanged: (val) {
                          setState(() => _pelvicPain = val.toInt());
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Bloating',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                        subtitle: const Text('Abdominal swelling or tightness', style: TextStyle(fontSize: 12)),
                        value: _bloating,
                        activeColor: AppTheme.accentMenstrual,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _bloating = val),
                      ),
                    ],
                  ),
                ),

                // Androgen Excess Section
                _buildSectionTitle('Androgen Excess (Skin & Hair)', Icons.face_retouching_natural),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Acne Severity', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _acneOptions.map((opt) {
                          final selected = _acneSeverity == opt;
                          return ChoiceChip(
                            label: Text(opt),
                            selected: selected,
                            selectedColor: AppTheme.primaryWellness.withAlpha(40),
                            checkmarkColor: AppTheme.primaryWellness,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: selected ? AppTheme.primaryWellness : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _acneSeverity = opt);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Alopecia (Hair Thinning)', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _alopeciaOptions.map((opt) {
                          final selected = _alopeciaSeverity == opt;
                          return ChoiceChip(
                            label: Text(opt),
                            selected: selected,
                            selectedColor: AppTheme.primaryWellness.withAlpha(40),
                            checkmarkColor: AppTheme.primaryWellness,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: selected ? AppTheme.primaryWellness : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _alopeciaSeverity = opt);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ferriman-Gallwey Score (Hirsutism)',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: _fgScore != null,
                            activeColor: AppTheme.primaryWellness,
                            onChanged: (val) {
                              setState(() {
                                _fgScore = val ? 0 : null;
                              });
                            },
                          ),
                        ],
                      ),
                      const Text(
                        'Standard scale for excess body hair growth (0-36)',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey),
                      ),
                      if (_fgScore != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score: $_fgScore',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _getFGInterpretation(_fgScore!),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _fgScore! >= 16
                                    ? AppTheme.glycemicHigh
                                    : (_fgScore! >= 8 ? AppTheme.glycemicMedium : AppTheme.glycemicLow),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _fgScore!.toDouble(),
                          min: 0,
                          max: 36,
                          divisions: 36,
                          activeColor: AppTheme.primaryWellness,
                          label: _fgScore.toString(),
                          onChanged: (val) {
                            setState(() => _fgScore = val.toInt());
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Insulin Resistance Markers Section
                _buildSectionTitle('Insulin Resistance & Metabolic', Icons.speed),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Food Cravings', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _cravingOptions.map((crav) {
                          final selected = _cravings.contains(crav);
                          return FilterChip(
                            label: Text(crav),
                            selected: selected,
                            selectedColor: AppTheme.primaryWellness.withAlpha(40),
                            checkmarkColor: AppTheme.primaryWellness,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: selected ? AppTheme.primaryWellness : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _cravings.add(crav);
                                } else {
                                  _cravings.remove(crav);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Acanthosis Nigricans',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                        subtitle: const Text('Dark, velvety skin patches (neck, armpits)', style: TextStyle(fontSize: 12)),
                        value: _acanthosisNigricans,
                        activeColor: AppTheme.primaryWellness,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _acanthosisNigricans = val),
                      ),
                      SwitchListTile(
                        title: const Text('Skin Tags',
                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                        subtitle: const Text('Small, benign skin growths', style: TextStyle(fontSize: 12)),
                        value: _skinTags,
                        activeColor: AppTheme.primaryWellness,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _skinTags = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Save Button
          ElevatedButton(
            onPressed: () async {
              final id = widget.initialSymptom?.id ??
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
              
              final log = SymptomEntity(
                id: id,
                timestamp: _selectedDate,
                ferrimanGallweyScore: _fgScore,
                acneSeverity: _acneSeverity,
                alopeciaSeverity: _alopeciaSeverity,
                fatigueLevel: _fatigueLevel,
                mood: _mood,
                cravings: _cravings,
                bloating: _bloating,
                pelvicPain: _pelvicPain,
                acanthosisNigricans: _acanthosisNigricans,
                skinTags: _skinTags,
                clientUpdatedTimestamp: DateTime.now(),
              );

              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(symptomStateNotifierProvider.notifier).addSymptomLog(log);
                if (mounted) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Symptom log saved successfully!'),
                      backgroundColor: AppTheme.glycemicLow,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error saving symptoms: $e'),
                      backgroundColor: AppTheme.glycemicHigh,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Log'),
          ),
        ],
      ),
    );
  }
}
