import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/cycle_provider.dart';
import '../../domain/entities/cycle_entity.dart';

// ─── Design tokens (Figma node 68:402) ───────────────────────────────────────

const _kPrimary = Color(0xFF5152B9);
const _kDarkText = Color(0xFF191C20);
const _kBodyText = Color(0xFF464552);
const _kMutedText = Color(0xFF777684);
const _kDayHeader = Color(0xFFC7C5D4);
const _kBg = Color(0xFFF8F9FF);
const _kDivider = Color(0xFFE7E8EE);

// Phase palette
const _kFollicularBg = Color(0x4DFFD6F8);
const _kFollicularDot = Color(0xFFFFD6F8);
const _kOvulatoryBg = Color(0x6693F2F3);
const _kOvulatoryDot = Color(0xFF93F2F3);
const _kLutealBg = Color(0x66E2DFFF);
const _kLutealDot = Color(0xFFE2DFFF);
const _kMenstrualBg = Color(0x4DEB505E);

// ─── Phase enum ───────────────────────────────────────────────────────────────

enum _Phase { none, menstrual, follicular, ovulatory, luteal }

// ─── Screen ───────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  _Phase _phaseForDate(DateTime date, List<CycleEntity> cycles) {
    final d = _norm(date);
    final logs = cycles.where((c) => !c.isPredicted).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    for (final cycle in logs) {
      final start = _norm(cycle.startDate);
      final end = cycle.endDate != null
          ? _norm(cycle.endDate!)
          : start.add(const Duration(days: 4));

      if (!d.isBefore(start) && !d.isAfter(end)) return _Phase.menstrual;

      final afterEnd = end.add(const Duration(days: 1));
      final daysSince = d.difference(afterEnd).inDays;
      if (daysSince >= 0 && daysSince < 8) return _Phase.follicular;
      if (daysSince >= 8 && daysSince < 16) return _Phase.ovulatory;
      if (daysSince >= 16 && daysSince < 28) return _Phase.luteal;
    }
    return _Phase.none;
  }

  String _phaseInfoText(List<CycleEntity> cycles) {
    final logs = cycles.where((c) => !c.isPredicted).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    if (logs.isEmpty) return 'Log your first cycle to begin tracking';

    final daysSince = _norm(DateTime.now()).difference(_norm(logs.first.startDate)).inDays;
    final cycleDay = daysSince + 1;
    if (cycleDay < 1) return 'Log your cycle to track phase';

    final phase = cycleDay <= 5
        ? 'Menstrual Phase'
        : cycleDay <= 13
            ? 'Follicular Phase'
            : cycleDay <= 17
                ? 'Ovulatory Phase'
                : 'Luteal Phase';
    return 'Day $cycleDay • $phase';
  }

  List<_TimelineEntry> _timelineEntries(List<CycleEntity> cycles) {
    final today = DateTime.now();
    final logs = cycles.where((c) => !c.isPredicted).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final entries = <_TimelineEntry>[];
    for (final cycle in logs) {
      for (final symptom in cycle.symptoms) {
        if (symptom.startsWith('mood:')) continue;
        final diff = today.difference(cycle.startDate).inDays;
        final timeLabel = diff == 0
            ? 'Today'
            : diff == 1
                ? 'Yesterday'
                : '$diff days ago';
        entries.add(_TimelineEntry(
          name: symptom,
          timeLabel: timeLabel,
          description: _symptomDescription(symptom),
          bubbleBg: _symptomBubbleBg(symptom),
          bubbleBorder: _symptomBubbleBorder(symptom),
          icon: _symptomIcon(symptom),
          iconColor: _symptomIconColor(symptom),
        ));
        if (entries.length == 3) break;
      }
      if (entries.length == 3) break;
    }

    // Fallback placeholder entries when no data logged yet
    if (entries.isEmpty) {
      entries.addAll([
        _TimelineEntry(
          name: 'Cystic Acne',
          timeLabel: '09:15 AM',
          description: 'Moderate flare-up on jawline. Likely related to androgen levels.',
          bubbleBg: const Color(0x4DFFB8F8),
          bubbleBorder: const Color(0xFFFFB8F8),
          icon: Icons.face_retouching_natural_outlined,
          iconColor: const Color(0xFFB85EC5),
        ),
        _TimelineEntry(
          name: 'Energy Dip',
          timeLabel: 'Yesterday',
          description: 'Severe afternoon crash despite adequate protein intake.',
          bubbleBg: const Color(0x338E8FFA),
          bubbleBorder: const Color(0x668E8FFA),
          icon: Icons.bolt_outlined,
          iconColor: _kPrimary,
        ),
        _TimelineEntry(
          name: 'Sugar Craving',
          timeLabel: '2 days ago',
          description: 'Intense craving for refined carbs during follicular transition.',
          bubbleBg: const Color(0x3345A8A9),
          bubbleBorder: const Color(0x6645A8A9),
          icon: Icons.local_dining_outlined,
          iconColor: const Color(0xFF45A8A9),
        ),
      ]);
    }

    return entries;
  }

  String _symptomDescription(String symptom) {
    const map = {
      'Cramps': 'Lower abdominal pain. May indicate high prostaglandin activity.',
      'Acne': 'Hormonal breakout. Associated with androgen fluctuations.',
      'Bloating': 'Abdominal fullness. Common during luteal and menstrual phases.',
      'Headache': 'Tension or hormonal headache. Monitor hydration.',
      'Backache': 'Lower back discomfort related to uterine contractions.',
      'Mood Swings': 'Emotional variability linked to estrogen/progesterone shifts.',
      'Fatigue': 'Persistent tiredness. Check iron and sleep quality.',
    };
    return map[symptom] ?? 'Logged symptom during your cycle.';
  }

  Color _symptomBubbleBg(String symptom) {
    if (['Cramps', 'Acne', 'Mood Swings'].contains(symptom)) {
      return const Color(0x4DFFB8F8);
    }
    if (['Fatigue', 'Headache'].contains(symptom)) {
      return const Color(0x338E8FFA);
    }
    return const Color(0x3345A8A9);
  }

  Color _symptomBubbleBorder(String symptom) {
    if (['Cramps', 'Acne', 'Mood Swings'].contains(symptom)) {
      return const Color(0xFFFFB8F8);
    }
    if (['Fatigue', 'Headache'].contains(symptom)) {
      return const Color(0x668E8FFA);
    }
    return const Color(0x6645A8A9);
  }

  IconData _symptomIcon(String symptom) {
    const map = {
      'Cramps': Icons.sick_outlined,
      'Acne': Icons.face_retouching_natural_outlined,
      'Bloating': Icons.water_outlined,
      'Headache': Icons.psychology_outlined,
      'Backache': Icons.accessibility_new_outlined,
      'Mood Swings': Icons.sentiment_very_dissatisfied_outlined,
      'Fatigue': Icons.bolt_outlined,
    };
    return map[symptom] ?? Icons.monitor_heart_outlined;
  }

  Color _symptomIconColor(String symptom) {
    if (['Cramps', 'Acne', 'Mood Swings'].contains(symptom)) {
      return const Color(0xFFB85EC5);
    }
    if (['Fatigue', 'Headache'].contains(symptom)) return _kPrimary;
    return const Color(0xFF45A8A9);
  }

  void _showLogCycleSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LogCycleSheet(
        initialDate: date,
        onSubmit: (start, end, flow, pain, symptoms) {
          ref.read(cycleStateNotifierProvider.notifier).addCycleLog(
                startDate: start,
                endDate: end,
                flowIntensity: flow,
                painLevel: pain,
                symptoms: symptoms,
              );
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cycleState = ref.watch(cycleStateNotifierProvider);

    if (cycleState.isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    final cycles = cycleState.cycles;

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
                  _buildPageHeader(cycles),
                  const SizedBox(height: 24),
                  _buildCalendarCard(cycles),
                  const SizedBox(height: 24),
                  _buildLogTodaySection(context),
                  const SizedBox(height: 24),
                  _buildSymptomTimeline(cycles),
                  const SizedBox(height: 24),
                  _buildInsightCard(),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
          _buildTopBar(),
          Positioned(
            bottom: 24,
            right: 20,
            child: _buildFAB(context),
          ),
        ],
      ),
    );
  }

  // ── Top App Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
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
                        color: _kPrimary.withOpacity(0.2), width: 2),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFE2DFFF),
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
                    icon: const Icon(Icons.notifications_outlined,
                        color: _kDarkText, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────────

  Widget _buildPageHeader(List<CycleEntity> cycles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Track Cycle',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            letterSpacing: -0.64,
            color: _kDarkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _phaseInfoText(cycles),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _kBodyText,
          ),
        ),
      ],
    );
  }

  // ── Calendar Card ─────────────────────────────────────────────────────────────

  Widget _buildCalendarCard(List<CycleEntity> cycles) {
    final today = _norm(DateTime.now());
    final monthLabel = _monthLabel(_displayMonth);
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final startOffset = (firstDay.weekday - 1) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5152B9).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            children: [
              Text(
                monthLabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: _kDarkText,
                ),
              ),
              const Spacer(),
              _MonthNavButton(
                icon: Icons.chevron_left,
                onTap: () => setState(() {
                  _displayMonth = DateTime(
                      _displayMonth.year, _displayMonth.month - 1);
                }),
              ),
              const SizedBox(width: 4),
              _MonthNavButton(
                icon: Icons.chevron_right,
                onTap: () => setState(() {
                  _displayMonth = DateTime(
                      _displayMonth.year, _displayMonth.month + 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Day-of-week headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kDayHeader,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              mainAxisSpacing: 8,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, i) {
              if (i < startOffset) return const SizedBox.shrink();

              final day = i - startOffset + 1;
              final date =
                  DateTime(_displayMonth.year, _displayMonth.month, day);
              final dateNorm = _norm(date);
              final isToday = dateNorm == today;
              final phase = _phaseForDate(date, cycles);

              return GestureDetector(
                onTap: () => _showLogCycleSheet(context, date),
                child: _DayCell(day: day, isToday: isToday, phase: phase),
              );
            },
          ),

          // Legend
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Divider(color: _kDivider, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: const [
                _LegendDot(color: _kFollicularDot, label: 'Follicular'),
                SizedBox(width: 16),
                _LegendDot(color: _kOvulatoryDot, label: 'Ovulatory'),
                SizedBox(width: 16),
                _LegendDot(color: _kLutealDot, label: 'Luteal'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Log for Today ─────────────────────────────────────────────────────────────

  Widget _buildLogTodaySection(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Log for Today',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: _kDarkText,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickLogButton(
                icon: Icons.water_drop_outlined,
                label: 'Flow',
                onTap: () => _showLogCycleSheet(context, now),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickLogButton(
                icon: Icons.sentiment_satisfied_alt_outlined,
                label: 'Mood',
                onTap: () => _showLogCycleSheet(context, now),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickLogButton(
                icon: Icons.battery_2_bar_outlined,
                label: 'Fatigue',
                onTap: () => _showLogCycleSheet(context, now),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Symptom Timeline ──────────────────────────────────────────────────────────

  Widget _buildSymptomTimeline(List<CycleEntity> cycles) {
    final entries = _timelineEntries(cycles);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Symptom Timeline',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: _kDarkText,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            // Vertical timeline line
            Positioned(
              left: 23,
              top: 16,
              bottom: 16,
              child: Container(width: 2, color: _kDivider),
            ),
            Column(
              children: entries
                  .map((e) => _TimelineItem(entry: e))
                  .toList(),
            ),
          ],
        ),
      ],
    );
  }

  // ── Clinical Insight Card ─────────────────────────────────────────────────────

  Widget _buildInsightCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.75, -0.66),
            end: Alignment(0.75, 0.66),
            colors: [Color(0xFF5152B9), Color(0xFF6C6DD1)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background icon (bottom-right, rotated, opaque)
            Positioned(
              bottom: -24,
              right: -24,
              child: Transform.rotate(
                angle: 0.21,
                child: Icon(
                  Icons.monitor_heart_outlined,
                  size: 120,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frosted badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Clinical Insight',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Metabolic Window',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your insulin sensitivity is peaking. This is the optimal time for high-intensity movement.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFFE2DFFF),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Read Analysis',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────────

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogCycleSheet(context, DateTime.now()),
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
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────────

  String _monthLabel(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20, color: _kDarkText),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.phase,
  });
  final int day;
  final bool isToday;
  final _Phase phase;

  Color get _bg {
    if (isToday) return _kPrimary;
    switch (phase) {
      case _Phase.follicular:
        return _kFollicularBg;
      case _Phase.ovulatory:
        return _kOvulatoryBg;
      case _Phase.luteal:
        return _kLutealBg;
      case _Phase.menstrual:
        return _kMenstrualBg;
      case _Phase.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _bg,
            shape: BoxShape.circle,
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: _kPrimary.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isToday ? Colors.white : _kDarkText,
            ),
          ),
        ),
        if (isToday) ...[
          const SizedBox(height: 3),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: _kPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kBodyText,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _kDarkText, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kDarkText,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────────

class _TimelineEntry {
  const _TimelineEntry({
    required this.name,
    required this.timeLabel,
    required this.description,
    required this.bubbleBg,
    required this.bubbleBorder,
    required this.icon,
    required this.iconColor,
  });
  final String name;
  final String timeLabel;
  final String description;
  final Color bubbleBg;
  final Color bubbleBorder;
  final IconData icon;
  final Color iconColor;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.entry});
  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: entry.bubbleBg,
              shape: BoxShape.circle,
              border: Border.all(color: entry.bubbleBorder),
            ),
            child: Icon(entry.icon, color: entry.iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.name,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _kDarkText,
                          ),
                        ),
                      ),
                      Text(
                        entry.timeLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kMutedText,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.4,
                      color: _kBodyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Cycle Bottom Sheet ───────────────────────────────────────────────────

class _LogCycleSheet extends StatefulWidget {
  const _LogCycleSheet({required this.initialDate, required this.onSubmit});

  final DateTime initialDate;
  final void Function(
    DateTime startDate,
    DateTime? endDate,
    FlowIntensity flowIntensity,
    int painLevel,
    List<String> symptoms,
  ) onSubmit;

  @override
  State<_LogCycleSheet> createState() => _LogCycleSheetState();
}

class _LogCycleSheetState extends State<_LogCycleSheet> {
  late DateTime _startDate;
  DateTime? _endDate;
  FlowIntensity _flow = FlowIntensity.medium;
  int _pain = 2;
  final List<String> _symptoms = [];
  String _mood = '😊 Happy';

  static const _moods = [
    '😊 Happy', '😔 Sad', '😠 Irritated', '😰 Anxious', '⚡ Energetic', '😴 Tired'
  ];
  static const _symptomOptions = [
    'Cramps', 'Acne', 'Bloating', 'Headache', 'Backache', 'Mood Swings', 'Fatigue'
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E8EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Log Menstrual Period',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 24),

            // Date row
            Row(
              children: [
                Expanded(child: _dateField('Start Date', _startDate, (d) {
                  setState(() => _startDate = d);
                })),
                const SizedBox(width: 12),
                Expanded(child: _dateField(
                  'End Date',
                  _endDate,
                  (d) => setState(() => _endDate = d),
                  nullable: true,
                  minDate: _startDate,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Flow intensity
            const Text('Flow Intensity',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kDarkText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: FlowIntensity.values.map((f) {
                final selected = _flow == f;
                return ChoiceChip(
                  label: Text(f.name.toUpperCase()),
                  selected: selected,
                  selectedColor: AppTheme.accentRoseWash,
                  checkmarkColor: AppTheme.accentMenstrual,
                  onSelected: (v) {
                    if (v) setState(() => _flow = f);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Pain level
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pain Level',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _kDarkText)),
                Text(
                  '$_pain / 5',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentMenstrual),
                ),
              ],
            ),
            Slider(
              value: _pain.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: AppTheme.accentMenstrual,
              onChanged: (v) => setState(() => _pain = v.round()),
            ),
            const SizedBox(height: 8),

            // Mood
            const Text('Your Mood',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kDarkText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((m) {
                final selected = _mood == m;
                return ChoiceChip(
                  label: Text(m),
                  selected: selected,
                  selectedColor: AppTheme.primaryLight,
                  onSelected: (v) {
                    if (v) setState(() => _mood = m);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Symptoms
            const Text('Symptoms Experienced',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _kDarkText)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptomOptions.map((s) {
                final selected = _symptoms.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  selectedColor: AppTheme.primaryLight,
                  checkmarkColor: AppTheme.primaryWellness,
                  onSelected: (v) => setState(() {
                    v ? _symptoms.add(s) : _symptoms.remove(s);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                widget.onSubmit(
                  _startDate,
                  _endDate,
                  _flow,
                  _pain,
                  [..._symptoms, 'mood:$_mood'],
                );
              },
              child: const Text('Save Period Log'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    void Function(DateTime) onPicked, {
    bool nullable = false,
    DateTime? minDate,
  }) {
    final display = value == null
        ? (nullable ? 'Ongoing' : '—')
        : '${value.day}/${value.month}/${value.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _kDarkText)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined, size: 14),
          label: Text(display,
              style:
                  const TextStyle(fontFamily: 'Inter', fontSize: 13)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? (minDate ?? DateTime.now()),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) onPicked(picked);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _kDivider),
          ),
        ),
      ],
    );
  }
}
