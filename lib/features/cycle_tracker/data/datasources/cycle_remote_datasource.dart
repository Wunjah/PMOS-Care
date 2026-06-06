import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cycle_model.dart';

abstract class CycleRemoteDataSource {
  Future<List<CycleModel>> getRemoteCycles();
  Future<void> saveRemoteCycle(CycleModel cycle);
  Future<void> deleteRemoteCycle(String cycleId);
}

class CycleRemoteDataSourceImpl implements CycleRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CycleRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _cycleCollection {
    return _firestore.collection('users').doc(_userId).collection('cycles');
  }

  @override
  Future<List<CycleModel>> getRemoteCycles() async {
    final snap = await _cycleCollection.orderBy('startDate', descending: true).get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return CycleModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteCycle(CycleModel cycle) async {
    final json = cycle.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _cycleCollection.doc(cycle.id).set(json);
  }

  @override
  Future<void> deleteRemoteCycle(String cycleId) async {
    await _cycleCollection.doc(cycleId).delete();
  }
}
