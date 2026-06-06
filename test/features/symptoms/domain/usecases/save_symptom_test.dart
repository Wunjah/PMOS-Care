import 'package:flutter_test/flutter_test.dart';
import 'package:pmos_care/features/symptoms/domain/entities/symptom_entity.dart';
import 'package:pmos_care/features/symptoms/domain/repositories/symptom_repository.dart';
import 'package:pmos_care/features/symptoms/domain/usecases/save_symptom_usecase.dart';

class MockSymptomRepository implements SymptomRepository {
  bool getSymptomsCalled = false;
  bool saveSymptomCalled = false;
  bool deleteSymptomCalled = false;
  bool syncOfflineDataCalled = false;

  final SymptomEntity mockSymptom = SymptomEntity(
    id: '2026-06-01',
    timestamp: DateTime(2026, 6, 1),
    acneSeverity: 'none',
    alopeciaSeverity: 'none',
    fatigueLevel: 2,
    mood: 'calm',
    cravings: [],
    bloating: false,
    pelvicPain: 1,
    acanthosisNigricans: false,
    skinTags: false,
    clientUpdatedTimestamp: DateTime.now(),
  );

  @override
  Future<List<SymptomEntity>> getSymptoms() async {
    getSymptomsCalled = true;
    return [mockSymptom];
  }

  @override
  Future<void> saveSymptom(SymptomEntity symptom) async {
    saveSymptomCalled = true;
  }

  @override
  Future<void> deleteSymptom(String symptomLogId) async {
    deleteSymptomCalled = true;
  }

  @override
  Future<void> syncOfflineData() async {
    syncOfflineDataCalled = true;
  }
}

void main() {
  late MockSymptomRepository mockRepository;
  late SaveSymptomUsecase saveSymptomUsecase;

  setUp(() {
    mockRepository = MockSymptomRepository();
    saveSymptomUsecase = SaveSymptomUsecase(mockRepository);
  });

  group('SaveSymptomUsecase Unit Tests', () {
    test('should call repository.saveSymptom for a valid symptom entity', () async {
      // Arrange
      final validSymptom = SymptomEntity(
        id: '2026-06-01',
        timestamp: DateTime(2026, 6, 1),
        acneSeverity: 'mild',
        alopeciaSeverity: 'none',
        fatigueLevel: 3, // Valid range 1-5
        mood: 'happy',
        cravings: ['sugar'],
        bloating: true,
        pelvicPain: 2, // Valid range 1-5
        acanthosisNigricans: true,
        skinTags: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act
      await saveSymptomUsecase.execute(validSymptom);

      // Assert
      expect(mockRepository.saveSymptomCalled, isTrue);
    });

    test('should throw exception when fatigueLevel is out of range (6)', () async {
      // Arrange
      final invalidSymptom = SymptomEntity(
        id: '2026-06-01',
        timestamp: DateTime(2026, 6, 1),
        acneSeverity: 'none',
        alopeciaSeverity: 'none',
        fatigueLevel: 6, // Invalid (max 5)
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => saveSymptomUsecase.execute(invalidSymptom),
        throwsA(isA<Exception>()),
      );
      expect(mockRepository.saveSymptomCalled, isFalse);
    });

    test('should throw exception when pelvicPain is out of range (0)', () async {
      // Arrange
      final invalidSymptom = SymptomEntity(
        id: '2026-06-01',
        timestamp: DateTime(2026, 6, 1),
        acneSeverity: 'none',
        alopeciaSeverity: 'none',
        fatigueLevel: 2,
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 0, // Invalid (min 1)
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => saveSymptomUsecase.execute(invalidSymptom),
        throwsA(isA<Exception>()),
      );
      expect(mockRepository.saveSymptomCalled, isFalse);
    });

    test('should throw exception when hirsutism score is out of range (37)', () async {
      // Arrange
      final invalidSymptom = SymptomEntity(
        id: '2026-06-01',
        timestamp: DateTime(2026, 6, 1),
        ferrimanGallweyScore: 37, // Invalid (max 36)
        acneSeverity: 'none',
        alopeciaSeverity: 'none',
        fatigueLevel: 2,
        mood: 'calm',
        cravings: [],
        bloating: false,
        pelvicPain: 1,
        acanthosisNigricans: false,
        skinTags: false,
        clientUpdatedTimestamp: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => saveSymptomUsecase.execute(invalidSymptom),
        throwsA(isA<Exception>()),
      );
      expect(mockRepository.saveSymptomCalled, isFalse);
    });
  });
}
