import '../entities/symptom_entity.dart';

abstract class SymptomRepository {
  Future<List<SymptomEntity>> getSymptoms();
  Future<void> saveSymptom(SymptomEntity symptom);
  Future<void> deleteSymptom(String symptomLogId);
  Future<void> syncOfflineData();
}
