import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/cycle_entity.dart';

class CalendarWidget extends StatefulWidget {
  final List<CycleEntity> cycles;
  final DateTime? predictedNextDate;
  final Function(DateTime selectedDate) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.cycles,
    this.predictedNextDate,
    required this.onDaySelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  bool _isPeriodDay(DateTime date) {
    for (final cycle in widget.cycles) {
      if (cycle.isPredicted) continue;
      final start = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      if (cycle.endDate != null) {
        final end = DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day);
        if (date.isAtSameMomentAs(start) || date.isAtSameMomentAs(end) || (date.isAfter(start) && date.isBefore(end))) {
          return true;
        }
      } else {
        if (date.isAtSameMomentAs(start)) return true;
      }
    }
    return false;
  }

  bool _isPredictedDay(DateTime date) {
    if (widget.predictedNextDate == null) return false;
    final target = DateTime(widget.predictedNextDate!.year, widget.predictedNextDate!.month, widget.predictedNextDate!.day);
    final rangeEnd = target.add(const Duration(days: 4));
    return date.isAtSameMomentAs(target) || (date.isAfter(target) && date.isBefore(rangeEnd));
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;

    final blankCellsCount = startingWeekday == 7 ? 0 : startingWeekday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(year, month - 1, 1);
                    });
                  },
                ),
                Text(
                  '${_monthName(month)} $year',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryWellness,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(year, month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _WeekdayLabel('S'),
                _WeekdayLabel('M'),
                _WeekdayLabel('T'),
                _WeekdayLabel('W'),
                _WeekdayLabel('T'),
                _WeekdayLabel('F'),
                _WeekdayLabel('S'),
              ],
            ),
            const Divider(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blankCellsCount + totalDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index < blankCellsCount) {
                  return const SizedBox.shrink();
                }
                
                final dayNumber = index - blankCellsCount + 1;
                final date = DateTime(year, month, dayNumber);
                final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
                final isPeriod = _isPeriodDay(date);
                final isPredicted = _isPredictedDay(date);

                Color? cellBg;
                Color textColor = AppTheme.textDark;
                Border? border;

                if (isPeriod) {
                  cellBg = AppTheme.accentMenstrual;
                  textColor = Colors.white;
                } else if (isPredicted) {
                  cellBg = AppTheme.accentRoseWash;
                  textColor = AppTheme.accentMenstrual;
                  border = Border.all(color: AppTheme.accentMenstrual, style: BorderStyle.solid);
                } else if (isToday) {
                  cellBg = AppTheme.primaryLight;
                  border = Border.all(color: AppTheme.primaryWellness, width: 2);
                  textColor = AppTheme.primaryWellness;
                }

                return GestureDetector(
                  onTap: () => widget.onDaySelected(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cellBg,
                      shape: BoxShape.circle,
                      border: border,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: (isToday || isPeriod || isPredicted) ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
