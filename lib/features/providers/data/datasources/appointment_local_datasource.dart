import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/appointment_model.dart';

abstract class AppointmentLocalDataSource {
  Future<List<AppointmentModel>> getCachedAppointments();
  Future<void> cacheAppointments(List<AppointmentModel> appointments);
  Future<void> cacheSingleAppointment(AppointmentModel appointment, {required bool needsSync});
  Future<void> removeCachedAppointment(String appointmentId, {required bool needsSyncDelete});
  Future<List<String>> getPendingDeletes();
  Future<List<AppointmentModel>> getUnsyncedAppointments();
  Future<void> clearCache();
}

class AppointmentLocalDataSourceImpl implements AppointmentLocalDataSource {
  static const String _appointmentBoxName = 'pmos_appointment_box';
  static const String _unsyncedKey = 'pmos_unsynced_appointments_list';
  static const String _pendingDeletesKey = 'pmos_pending_appointment_deletes_list';

  final Box _hiveBox;

  AppointmentLocalDataSourceImpl(this._hiveBox);

  @override
  Future<List<AppointmentModel>> getCachedAppointments() async {
    final List<dynamic>? jsonList = _hiveBox.get(_appointmentBoxName) as List<dynamic>?;
    if (jsonList == null) return [];
    return jsonList
        .map((e) => AppointmentModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cacheAppointments(List<AppointmentModel> appointments) async {
    final jsonList = appointments.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_appointmentBoxName, jsonList);
  }

  @override
  Future<void> cacheSingleAppointment(AppointmentModel appointment, {required bool needsSync}) async {
    final list = await getCachedAppointments();
    final index = list.indexWhere((element) => element.id == appointment.id);
    if (index != -1) {
      list[index] = appointment;
    } else {
      list.add(appointment);
    }
    await cacheAppointments(list);

    if (needsSync) {
      final unsynced = await getUnsyncedAppointments();
      final uIndex = unsynced.indexWhere((element) => element.id == appointment.id);
      if (uIndex != -1) {
        unsynced[uIndex] = appointment;
      } else {
        unsynced.add(appointment);
      }
      final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
      await _hiveBox.put(_unsyncedKey, jsonList);
    }
  }

  @override
  Future<void> removeCachedAppointment(String appointmentId, {required bool needsSyncDelete}) async {
    final list = await getCachedAppointments();
    list.removeWhere((element) => element.id == appointmentId);
    await cacheAppointments(list);

    final unsynced = await getUnsyncedAppointments();
    unsynced.removeWhere((element) => element.id == appointmentId);
    final jsonList = unsynced.map((e) => jsonEncode(e.toJson())).toList();
    await _hiveBox.put(_unsyncedKey, jsonList);

    if (needsSyncDelete) {
      final deletes = await getPendingDeletes();
      if (!deletes.contains(appointmentId)) {
        deletes.add(appointmentId);
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
  Future<List<AppointmentModel>> getUnsyncedAppointments() async {
    final List<dynamic>? unsyncedJson = _hiveBox.get(_unsyncedKey) as List<dynamic>?;
    if (unsyncedJson == null) return [];
    return unsyncedJson
        .map((e) => AppointmentModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _hiveBox.delete(_appointmentBoxName);
    await _hiveBox.delete(_unsyncedKey);
    await _hiveBox.delete(_pendingDeletesKey);
  }
}
