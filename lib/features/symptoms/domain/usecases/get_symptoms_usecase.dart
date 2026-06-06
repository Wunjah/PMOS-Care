import '../entities/symptom_entity.dart';
import '../repositories/symptom_repository.dart';

class GetSymptomsUsecase {
  final SymptomRepository repository;

  GetSymptomsUsecase(this.repository);

  Future<List<SymptomEntity>> execute() async {
    return await repository.getSymptoms();
  }
}
