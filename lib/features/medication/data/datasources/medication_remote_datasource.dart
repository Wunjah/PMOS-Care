import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';

abstract class MedicationRemoteDataSource {
  Future<List<MedicationModel>> getRemoteMedications();
  Future<void> saveRemoteMedication(MedicationModel medication);
  Future<void> deleteRemoteMedication(String medicationId);
}

class MedicationRemoteDataSourceImpl implements MedicationRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  MedicationRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _medicationCollection {
    return _firestore.collection('users').doc(_userId).collection('medications');
  }

  @override
  Future<List<MedicationModel>> getRemoteMedications() async {
    final snap = await _medicationCollection.orderBy('name').get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return MedicationModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteMedication(MedicationModel medication) async {
    final json = medication.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _medicationCollection.doc(medication.id).set(json);
  }

  @override
  Future<void> deleteRemoteMedication(String medicationId) async {
    await _medicationCollection.doc(medicationId).delete();
  }
}
