import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/cycle_entity.dart';

class CycleCharts extends StatelessWidget {
  final List<CycleEntity> cycles;

  const CycleCharts({super.key, required this.cycles});

  @override
  Widget build(BuildContext context) {
    final userLogs = cycles.where((e) => !e.isPredicted).toList();
    userLogs.sort((a, b) => b.startDate.compareTo(a.startDate));

    if (userLogs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No past periods logged yet.\nYour cycle trends will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final displayLogs = userLogs.take(4).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle Length History',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryWellness,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayLogs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = displayLogs[index];
                
                final flowDays = log.endDate != null 
                    ? log.endDate!.difference(log.startDate).inDays + 1 
                    : 5;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Started ${_formatDate(log.startDate)}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$flowDays flow days',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.accentMenstrual, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (flowDays / 14).clamp(0.1, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentMenstrual, AppTheme.brandActive],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
