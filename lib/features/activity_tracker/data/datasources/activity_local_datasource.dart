import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/activity_model.dart';

abstract class ActivityLocalDataSource {
  Future<List<ActivityModel>> getCachedActivities();
  Future<void> cacheActivities(List<ActivityModel> activities);
  Future<void> cacheSingleActivity(ActivityModel activity, {required bool needsSync});
  Future<void> removeCachedActivity(String activityLogId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<ActivityModel>> getUnsyncedActivities();
  Future<void> clearCache();
}

class ActivityLocalDataSourceImpl implements ActivityLocalDataSource {
  static const String _activityBoxName = 'pmos_activity_box';
  static const String _unsyncedKey = 'pmos_unsynced_activities_list';
  static const String _pendingDeletesKey = 'pmos_pending_activity_deletes_list';

  final Box _hiveBox;

  ActivityLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<ActivityModel>> getCachedActivities() async {
    final List<dynamic>? activitiesJson = _hiveBox.get(_activityBoxName) as List<dynamic>?;
    if (activitiesJson == null) return [];
    return activitiesJson
        .map((e) => ActivityModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheActivities(List<ActivityModel> activities) async {
    final jsonList = activities.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_activityBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleActivity(ActivityModel activity, {required bool needsSync}) async {
    final list = await getCachedActivities();
    final index = list.indexWhere((element) => element.id == activity.id);
    if (index != -1) {
      list[index] = activity;
    } else {
      list.add(activity);
    }
    await cacheActivities(list);

    if (needsSync) {
      final unsynced = await getUnsyncedActivities();
      final uIndex = unsynced.indexWhere((element) => element.id == activity.id);
      if (uIndex != -1) {
        unsynced[uIndex] = activity;
      } else {
        unsynced.add(activity);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedActivity(String activityLogId, {required bool needsSyncDelete}) async {
    final list = await getCachedActivities();
    list.removeWhere((element) => element.id == activityLogId);
    await cacheActivities(list);

    final unsynced = await getUnsyncedActivities();
    unsynced.removeWhere((element) => element.id == activityLogId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(activityLogId)) {
        deletes.add(activityLogId);
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
  Future<List<ActivityModel>> getUnsyncedActivities() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson
        .map((e) => ActivityModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_activityBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
