import '../entities/cycle_entity.dart';

class PredictNextCycleUsecase {
  static const int pmosDefaultCycleLengthDays = 35;

  DateTime execute(List<CycleEntity> cycles) {
    final userLogs = cycles.where((e) => !e.isPredicted).toList();
    userLogs.sort((a, b) => a.startDate.compareTo(b.startDate));

    if (userLogs.isEmpty) {
      return DateTime.now().add(const Duration(days: pmosDefaultCycleLengthDays));
    }

    if (userLogs.length < 2) {
      return userLogs.last.startDate.add(const Duration(days: pmosDefaultCycleLengthDays));
    }

    final List<int> cycleLengths = [];
    for (int i = 0; i < userLogs.length - 1; i++) {
      final difference = userLogs[i + 1].startDate.difference(userLogs[i].startDate).inDays;
      
      if (difference >= 15 && difference <= 120) {
        cycleLengths.add(difference);
      }
    }

    int averageLength = pmosDefaultCycleLengthDays;
    if (cycleLengths.isNotEmpty) {
      final totalDays = cycleLengths.reduce((a, b) => a + b);
      averageLength = (totalDays / cycleLengths.length).round();
    }

    final lastLogDate = userLogs.last.startDate;
    return lastLogDate.add(Duration(days: averageLength));
  }
}
