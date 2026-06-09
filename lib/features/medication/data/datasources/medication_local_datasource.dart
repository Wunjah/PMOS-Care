import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/medication_model.dart';

abstract class MedicationLocalDataSource {
  Future<List<MedicationModel>> getCachedMedications();
  Future<void> cacheMedications(List<MedicationModel> medications);
  Future<void> cacheSingleMedication(MedicationModel medication, {required bool needsSync});
  Future<void> removeCachedMedication(String medicationId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<MedicationModel>> getUnsyncedMedications();
  Future<void> clearCache();
}

class MedicationLocalDataSourceImpl implements MedicationLocalDataSource {
  static const String _medBoxName = 'pmos_medication_box';
  static const String _unsyncedKey = 'pmos_unsynced_medications_list';
  static const String _pendingDeletesKey = 'pmos_pending_medication_deletes_list';

  final Box _hiveBox;

  MedicationLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<MedicationModel>> getCachedMedications() async {
    final List<dynamic>? medsJson = _hiveBox.get(_medBoxName) as List<dynamic>?;
    if (medsJson == null) return [];
    return medsJson
        .map((e) => MedicationModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheMedications(List<MedicationModel> medications) async {
    final jsonList = medications.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_medBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleMedication(MedicationModel medication, {required bool needsSync}) async {
    final list = await getCachedMedications();
    final index = list.indexWhere((element) => element.id == medication.id);
    if (index != -1) {
      list[index] = medication;
    } else {
      list.add(medication);
    }
    await cacheMedications(list);

    if (needsSync) {
      final unsynced = await getUnsyncedMedications();
      final uIndex = unsynced.indexWhere((element) => element.id == medication.id);
      if (uIndex != -1) {
        unsynced[uIndex] = medication;
      } else {
        unsynced.add(medication);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedMedication(String medicationId, {required bool needsSyncDelete}) async {
    final list = await getCachedMedications();
    list.removeWhere((element) => element.id == medicationId);
    await cacheMedications(list);

    final unsynced = await getUnsyncedMedications();
    unsynced.removeWhere((element) => element.id == medicationId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(medicationId)) {
        deletes.add(medicationId);
        await _hiveBox.put(_pendingDeletesKey, deletes);
      }
    }
  }

  @override
  Future<List<String>> getPendingDeletes() async {
    final List<dynamic>? deletes = _hiveBox.get(_pendingDeletesKey) as List<dynamic>?;
    return deletes != null ? List<String>.from(deletes) : [];
  }

  @override
  Future<List<MedicationModel>> getUnsyncedMedications() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson
        .map((e) => MedicationModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_medBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
