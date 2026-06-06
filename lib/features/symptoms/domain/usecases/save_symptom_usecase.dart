import '../entities/symptom_entity.dart';
import '../repositories/symptom_repository.dart';

class SaveSymptomUsecase {
  final SymptomRepository repository;

  SaveSymptomUsecase(this.repository);

  Future<void> execute(SymptomEntity symptom) async {
    if (symptom.fatigueLevel < 1 || symptom.fatigueLevel > 5) {
      throw Exception('Fatigue level must be a value between 1 and 5.');
    }
    if (symptom.pelvicPain < 1 || symptom.pelvicPain > 5) {
      throw Exception('Pelvic pain level must be a value between 1 and 5.');
    }
    if (symptom.ferrimanGallweyScore != null && 
        (symptom.ferrimanGallweyScore! < 0 || symptom.ferrimanGallweyScore! > 36)) {
      throw Exception('Hirsutism Ferriman-Gallwey score must be a value between 0 and 36.');
    }
    
    return await repository.saveSymptom(symptom);
  }
}
