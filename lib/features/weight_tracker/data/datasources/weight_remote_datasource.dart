import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weight_model.dart';

abstract class WeightRemoteDataSource {
  Future<List<WeightModel>> getRemoteWeights();
  Future<void> saveRemoteWeight(WeightModel weight);
  Future<void> deleteRemoteWeight(String weightLogId);
}

class WeightRemoteDataSourceImpl implements WeightRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  WeightRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _weightCollection {
    return _firestore.collection('users').doc(_userId).collection('weight');
  }

  @override
  Future<List<WeightModel>> getRemoteWeights() async {
    final snap = await _weightCollection.orderBy('timestamp', descending: true).get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return WeightModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteWeight(WeightModel weight) async {
    final json = weight.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _weightCollection.doc(weight.id).set(json);
  }

  @override
  Future<void> deleteRemoteWeight(String weightLogId) async {
    await _weightCollection.doc(weightLogId).delete();
  }
}
