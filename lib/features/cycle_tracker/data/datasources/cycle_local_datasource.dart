import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/cycle_model.dart';

abstract class CycleLocalDataSource {
  Future<List<CycleModel>> getCachedCycles();
  Future<void> cacheCycles(List<CycleModel> cycles);
  Future<void> cacheSingleCycle(CycleModel cycle, {required bool needsSync});
  Future<void> removeCachedCycle(String cycleId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<CycleModel>> getUnsyncedCycles();
  Future<void> clearCache();
}

class CycleLocalDataSourceImpl implements CycleLocalDataSource {
  static const String _cycleBoxName = 'pmos_cycle_box';
  static const String _unsyncedKey = 'pmos_unsynced_cycles_list';
  static const String _pendingDeletesKey = 'pmos_pending_deletes_list';

  final Box _hiveBox;

  CycleLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<CycleModel>> getCachedCycles() async {
    final List<dynamic>? cyclesJson = _hiveBox.get(_cycleBoxName) as List<dynamic>?;
    if (cyclesJson == null) return [];
    return cyclesJson.map((e) => CycleModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> cacheCycles(List<CycleModel> cycles) async {
    final jsonList = cycles.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_cycleBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleCycle(CycleModel cycle, {required bool needsSync}) async {
    final list = await getCachedCycles();
    final index = list.indexWhere((element) => element.id == cycle.id);
    if (index != -1) {
      list[index] = cycle;
    } else {
      list.add(cycle);
    }
    await cacheCycles(list);

    if (needsSync) {
      final unsynced = await getUnsyncedCycles();
      final uIndex = unsynced.indexWhere((element) => element.id == cycle.id);
      if (uIndex != -1) {
        unsynced[uIndex] = cycle;
      } else {
        unsynced.add(cycle);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedCycle(String cycleId, {required bool needsSyncDelete}) async {
    final list = await getCachedCycles();
    list.removeWhere((element) => element.id == cycleId);
    await cacheCycles(list);

    final unsynced = await getUnsyncedCycles();
    unsynced.removeWhere((element) => element.id == cycleId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(cycleId)) {
        deletes.add(cycleId);
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
  Future<List<CycleModel>> getUnsyncedCycles() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson.map((e) => CycleModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_cycleBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
