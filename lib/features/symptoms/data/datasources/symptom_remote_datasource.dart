import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/symptom_model.dart';

abstract class SymptomRemoteDataSource {
  Future<List<SymptomModel>> getRemoteSymptoms();
  Future<void> saveRemoteSymptom(SymptomModel symptom);
  Future<void> deleteRemoteSymptom(String symptomLogId);
}

class SymptomRemoteDataSourceImpl implements SymptomRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  SymptomRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _symptomCollection {
    return _firestore.collection('users').doc(_userId).collection('symptoms');
  }

  @override
  Future<List<SymptomModel>> getRemoteSymptoms() async {
    final snap = await _symptomCollection.orderBy('timestamp', descending: true).get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return SymptomModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteSymptom(SymptomModel symptom) async {
    final json = symptom.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _symptomCollection.doc(symptom.id).set(json);
  }

  @override
  Future<void> deleteRemoteSymptom(String symptomLogId) async {
    await _symptomCollection.doc(symptomLogId).delete();
  }
}
