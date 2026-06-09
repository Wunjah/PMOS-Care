import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/weight_model.dart';

abstract class WeightLocalDataSource {
  Future<List<WeightModel>> getCachedWeights();
  Future<void> cacheWeights(List<WeightModel> weights);
  Future<void> cacheSingleWeight(WeightModel weight, {required bool needsSync});
  Future<void> removeCachedWeight(String weightLogId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<WeightModel>> getUnsyncedWeights();
  Future<void> clearCache();
}

class WeightLocalDataSourceImpl implements WeightLocalDataSource {
  static const String _weightBoxName = 'pmos_weight_box';
  static const String _unsyncedKey = 'pmos_unsynced_weights_list';
  static const String _pendingDeletesKey = 'pmos_pending_weight_deletes_list';

  final Box _hiveBox;

  WeightLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<WeightModel>> getCachedWeights() async {
    final List<dynamic>? weightsJson = _hiveBox.get(_weightBoxName) as List<dynamic>?;
    if (weightsJson == null) return [];
    return weightsJson
        .map((e) => WeightModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheWeights(List<WeightModel> weights) async {
    final jsonList = weights.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_weightBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleWeight(WeightModel weight, {required bool needsSync}) async {
    final list = await getCachedWeights();
    final index = list.indexWhere((element) => element.id == weight.id);
    if (index != -1) {
      list[index] = weight;
    } else {
      list.add(weight);
    }
    await cacheWeights(list);

    if (needsSync) {
      final unsynced = await getUnsyncedWeights();
      final uIndex = unsynced.indexWhere((element) => element.id == weight.id);
      if (uIndex != -1) {
        unsynced[uIndex] = weight;
      } else {
        unsynced.add(weight);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedWeight(String weightLogId, {required bool needsSyncDelete}) async {
    final list = await getCachedWeights();
    list.removeWhere((element) => element.id == weightLogId);
    await cacheWeights(list);

    final unsynced = await getUnsyncedWeights();
    unsynced.removeWhere((element) => element.id == weightLogId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(weightLogId)) {
        deletes.add(weightLogId);
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
  Future<List<WeightModel>> getUnsyncedWeights() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson
        .map((e) => WeightModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_weightBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
