import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/meal_log_model.dart';

abstract class MealLogLocalDataSource {
  Future<List<MealLogModel>> getCachedMealLogs();
  Future<void> cacheMealLogs(List<MealLogModel> logs);
  Future<void> cacheSingleMealLog(MealLogModel log, {required bool needsSync});
  Future<void> removeCachedMealLog(String logId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<MealLogModel>> getUnsyncedMealLogs();
  Future<void> clearCache();
}

class MealLogLocalDataSourceImpl implements MealLogLocalDataSource {
  static const String _dietBoxName = 'pmos_diet_box';
  static const String _unsyncedKey = 'pmos_unsynced_diet_list';
  static const String _pendingDeletesKey = 'pmos_pending_diet_deletes_list';

  final Box _hiveBox;

  MealLogLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<MealLogModel>> getCachedMealLogs() async {
    final List<dynamic>? logsJson = _hiveBox.get(_dietBoxName) as List<dynamic>?;
    if (logsJson == null) return [];
    return logsJson
        .map((e) => MealLogModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheMealLogs(List<MealLogModel> logs) async {
    final jsonList = logs.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_dietBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleMealLog(MealLogModel log, {required bool needsSync}) async {
    final list = await getCachedMealLogs();
    final index = list.indexWhere((element) => element.id == log.id);
    if (index != -1) {
      list[index] = log;
    } else {
      list.add(log);
    }
    await cacheMealLogs(list);

    if (needsSync) {
      final unsynced = await getUnsyncedMealLogs();
      final uIndex = unsynced.indexWhere((element) => element.id == log.id);
      if (uIndex != -1) {
        unsynced[uIndex] = log;
      } else {
        unsynced.add(log);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedMealLog(String logId, {required bool needsSyncDelete}) async {
    final list = await getCachedMealLogs();
    list.removeWhere((element) => element.id == logId);
    await cacheMealLogs(list);

    final unsynced = await getUnsyncedMealLogs();
    unsynced.removeWhere((element) => element.id == logId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(logId)) {
        deletes.add(logId);
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
  Future<List<MealLogModel>> getUnsyncedMealLogs() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson
        .map((e) => MealLogModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_dietBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
