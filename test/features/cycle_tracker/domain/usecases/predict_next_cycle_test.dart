import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/features/cycle_tracker/domain/entities/cycle_entity.dart';
import 'package:pmos_care/features/cycle_tracker/domain/usecases/predict_next_cycle_usecase.dart';

void main() {
  late PredictNextCycleUsecase predictNextCycleUsecase;

  setUp(() {
    predictNextCycleUsecase = PredictNextCycleUsecase();
  });

  group('PredictNextCycleUsecase Unit Tests', () {
    test('should return DateTime 35 days from now when cycles list is empty', () {
      // Act
      final result = predictNextCycleUsecase.execute([]);

      // Assert
      final target = DateTime.now().add(const Duration(days: 35));
      // Compare by day difference to ignore microsecond offsets of runtime execution
      expect(result.difference(target).inHours.abs() < 1, isTrue);
    });

    test('should return DateTime 35 days from last log when cycles list has 1 item', () {
      // Arrange
      final baseDate = DateTime(2026, 6, 1);
      final singleLog = CycleEntity(
        id: '1',
        startDate: baseDate,
        flowIntensity: FlowIntensity.medium,
        painLevel: 2,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act
      final result = predictNextCycleUsecase.execute([singleLog]);

      // Assert
      expect(result, equals(DateTime(2026, 7, 6))); // June 1 + 35 days = July 6
    });

    test('should calculate average length and project date when list has multiple items', () {
      // Arrange
      // Log 1: Jan 1, Log 2: Feb 5 (difference of 35 days), Log 3: Mar 10 (difference of 33 days)
      // Average spacing: (35 + 33) / 2 = 34 days
      // Last log: Mar 10. Prediction = Mar 10 + 34 days = April 13
      final log1 = CycleEntity(
        id: '1',
        startDate: DateTime(2026, 1, 1),
        flowIntensity: FlowIntensity.medium,
        painLevel: 2,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );
      final log2 = CycleEntity(
        id: '2',
        startDate: DateTime(2026, 2, 5),
        flowIntensity: FlowIntensity.medium,
        painLevel: 2,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );
      final log3 = CycleEntity(
        id: '3',
        startDate: DateTime(2026, 3, 10),
        flowIntensity: FlowIntensity.medium,
        painLevel: 3,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act
      final result = predictNextCycleUsecase.execute([log1, log2, log3]);

      // Assert
      expect(result, equals(DateTime(2026, 4, 13)));
    });

    test('should exclude anomaly spacings when computing average cycle length', () {
      // Arrange
      // Log 1: Jan 1, Log 2: Jan 5 (anomaly: 4 days spacing - should be excluded)
      // Log 3: Feb 5 (spacing Log 2 -> Log 3: 31 days - valid)
      // Since only 1 spacing is valid (31 days), average is 31 days.
      // Last log: Feb 5. Prediction = Feb 5 + 31 days = March 8
      final log1 = CycleEntity(
        id: '1',
        startDate: DateTime(2026, 1, 1),
        flowIntensity: FlowIntensity.heavy,
        painLevel: 3,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );
      final log2 = CycleEntity(
        id: '2',
        startDate: DateTime(2026, 1, 5), // Spacing is 4 days (anomaly)
        flowIntensity: FlowIntensity.light,
        painLevel: 1,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );
      final log3 = CycleEntity(
        id: '3',
        startDate: DateTime(2026, 2, 5), // Spacing is 31 days (valid)
        flowIntensity: FlowIntensity.medium,
        painLevel: 2,
        symptoms: [],
        isPredicted: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act
      final result = predictNextCycleUsecase.execute([log1, log2, log3]);

      // Assert
      expect(result, equals(DateTime(2026, 3, 8)));
    });
  });
}
