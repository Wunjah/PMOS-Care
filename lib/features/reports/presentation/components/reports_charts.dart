import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../weight_tracker/domain/entities/weight_entity.dart';
import '../../../activity_tracker/domain/entities/activity_entity.dart';
import '../../../diet/domain/entities/meal_log_entity.dart';
import '../../../symptoms/domain/entities/symptom_entity.dart';

class WeightChart extends StatelessWidget {
  final List<WeightEntity> weights;

  const WeightChart({super.key, required this.weights});

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Log weight in Weight Tracker to see trends.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    final displayed = weights.take(7).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < displayed.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayed[i].weightKg));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weight Trend (kg)',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryWellness),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayed.length) {
                        final date = displayed[idx].timestamp;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryWellness,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryWellness.withAlpha(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ActivityChart extends StatelessWidget {
  final List<ActivityEntity> activities;

  const ActivityChart({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Log activities to view calories burned trends.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    final displayed = activities.take(7).toList().reversed.toList();
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < displayed.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: displayed[i].caloriesBurned,
              color: Colors.orange,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Calories Burned (kcal)',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayed.length) {
                        final date = displayed[idx].timestamp;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}

class NutritionChart extends StatelessWidget {
  final List<MealLogEntity> mealLogs;

  const NutritionChart({super.key, required this.mealLogs});

  @override
  Widget build(BuildContext context) {
    // Group calories by date for the last 7 active days
    final Map<String, double> dailyCals = {};
    for (final log in mealLogs) {
      if (log.mealType == 'water') continue;
      final key = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
      dailyCals[key] = (dailyCals[key] ?? 0) + log.calories;
    }

    if (dailyCals.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Log meals to track daily calorie intake.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    final sortedKeys = dailyCals.keys.toList()..sort();
    final displayedKeys = sortedKeys.take(7).toList();

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < displayedKeys.length; i++) {
      final key = displayedKeys[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dailyCals[key]!,
              color: Colors.amber,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Caloric Intake (kcal)',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayedKeys.length) {
                        final parts = displayedKeys[idx].split('-');
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${parts[1]}/${parts[2]}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}

class SymptomSeverityChart extends StatelessWidget {
  final List<SymptomEntity> symptoms;

  const SymptomSeverityChart({super.key, required this.symptoms});

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Log symptoms to view severity trends.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    final displayed = symptoms.take(7).toList().reversed.toList();
    final fatigueSpots = <FlSpot>[];
    final painSpots = <FlSpot>[];

    for (int i = 0; i < displayed.length; i++) {
      fatigueSpots.add(FlSpot(i.toDouble(), displayed[i].fatigueLevel.toDouble()));
      painSpots.add(FlSpot(i.toDouble(), displayed[i].pelvicPain.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Symptom Severity (Scale 1-5)',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.accentMenstrual),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              minY: 1,
              maxY: 5,
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < displayed.length) {
                        final date = displayed[idx].timestamp;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: fatigueSpots,
                  isCurved: true,
                  color: AppTheme.primaryWellness,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: painSpots,
                  isCurved: true,
                  color: AppTheme.accentMenstrual,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 4, color: AppTheme.primaryWellness),
            const SizedBox(width: 4),
            const Text('Fatigue', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 16),
            Container(width: 12, height: 4, color: AppTheme.accentMenstrual),
            const SizedBox(width: 4),
            const Text('Pelvic Pain', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
