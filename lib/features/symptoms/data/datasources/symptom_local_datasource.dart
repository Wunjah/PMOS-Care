import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/symptom_model.dart';

abstract class SymptomLocalDataSource {
  Future<List<SymptomModel>> getCachedSymptoms();
  Future<void> cacheSymptoms(List<SymptomModel> symptoms);
  Future<void> cacheSingleSymptom(SymptomModel symptom, {required bool needsSync});
  Future<void> removeCachedSymptom(String symptomLogId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<SymptomModel>> getUnsyncedSymptoms();
  Future<void> clearCache();
}

class SymptomLocalDataSourceImpl implements SymptomLocalDataSource {
  static const String _symptomBoxName = 'pmos_symptom_box';
  static const String _unsyncedKey = 'pmos_unsynced_symptoms_list';
  static const String _pendingDeletesKey = 'pmos_pending_symptom_deletes_list';

  final Box _hiveBox;

  SymptomLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<SymptomModel>> getCachedSymptoms() async {
    final List<dynamic>? symptomsJson = _hiveBox.get(_symptomBoxName) as List<dynamic>?;
    if (symptomsJson == null) return [];
    return symptomsJson
        .map((e) => SymptomModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheSymptoms(List<SymptomModel> symptoms) async {
    final jsonList = symptoms.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_symptomBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleSymptom(SymptomModel symptom, {required bool needsSync}) async {
    final list = await getCachedSymptoms();
    final index = list.indexWhere((element) => element.id == symptom.id);
    if (index != -1) {
      list[index] = symptom;
    } else {
      list.add(symptom);
    }
    await cacheSymptoms(list);

    if (needsSync) {
      final unsynced = await getUnsyncedSymptoms();
      final uIndex = unsynced.indexWhere((element) => element.id == symptom.id);
      if (uIndex != -1) {
        unsynced[uIndex] = symptom;
      } else {
        unsynced.add(symptom);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedSymptom(String symptomLogId, {required bool needsSyncDelete}) async {
    final list = await getCachedSymptoms();
    list.removeWhere((element) => element.id == symptomLogId);
    await cacheSymptoms(list);

    final unsynced = await getUnsyncedSymptoms();
    unsynced.removeWhere((element) => element.id == symptomLogId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(symptomLogId)) {
        deletes.add(symptomLogId);
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
  Future<List<SymptomModel>> getUnsyncedSymptoms() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson
        .map((e) => SymptomModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_symptomBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
