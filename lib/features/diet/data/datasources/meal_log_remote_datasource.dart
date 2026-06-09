import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_log_model.dart';

abstract class MealLogRemoteDataSource {
  Future<List<MealLogModel>> getRemoteMealLogs();
  Future<void> saveRemoteMealLog(MealLogModel log);
  Future<void> deleteRemoteMealLog(String logId);
}

class MealLogRemoteDataSourceImpl implements MealLogRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  MealLogRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _dietCollection {
    return _firestore.collection('users').doc(_userId).collection('diet_logs');
  }

  @override
  Future<List<MealLogModel>> getRemoteMealLogs() async {
    final snap = await _dietCollection.orderBy('timestamp', descending: true).get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return MealLogModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteMealLog(MealLogModel log) async {
    final json = log.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _dietCollection.doc(log.id).set(json);
  }

  @override
  Future<void> deleteRemoteMealLog(String logId) async {
    await _dietCollection.doc(logId).delete();
  }
}
