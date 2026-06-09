import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getRemoteAppointments();
  Future<void> saveRemoteAppointment(AppointmentModel appointment);
  Future<void> deleteRemoteAppointment(String appointmentId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  AppointmentRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _appointmentCollection {
    return _firestore.collection('users').doc(_userId).collection('appointments');
  }

  @override
  Future<List<AppointmentModel>> getRemoteAppointments() async {
    final snap = await _appointmentCollection.orderBy('dateTime', descending: true).get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return AppointmentModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteAppointment(AppointmentModel appointment) async {
    final json = appointment.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _appointmentCollection.doc(appointment.id).set(json);
  }

  @override
  Future<void> deleteRemoteAppointment(String appointmentId) async {
    await _appointmentCollection.doc(appointmentId).delete();
  }
}
