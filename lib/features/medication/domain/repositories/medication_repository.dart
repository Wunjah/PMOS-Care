import '../entities/medication_entity.dart';

abstract class MedicationRepository {
  Future<List<MedicationEntity>> getMedications();
  Future<void> saveMedication(MedicationEntity medication);
  Future<void> deleteMedication(String medicationId);
  Future<void> syncOfflineData();
}
