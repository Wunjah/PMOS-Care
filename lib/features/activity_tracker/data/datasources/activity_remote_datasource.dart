import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_model.dart';

abstract class ActivityRemoteDataSource {
  Future<List<ActivityModel>> getRemoteActivities();
  Future<void> saveRemoteActivity(ActivityModel activity);
  Future<void> deleteRemoteActivity(String activityLogId);
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  ActivityRemoteDataSourceImpl(this._firestore, this._firebaseAuth);

  String get _userId {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user session found.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _activityCollection {
    return _firestore.collection('users').doc(_userId).collection('activities');
  }

  @override
  Future<List<ActivityModel>> getRemoteActivities() async {
    final snap = await _activityCollection.orderBy('timestamp', descending: true).get();
    return snap.docs.map((doc) {
      final json = doc.data();
      json['id'] = doc.id;
      return ActivityModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> saveRemoteActivity(ActivityModel activity) async {
    final json = activity.toJson();
    json['serverTimestamp'] = FieldValue.serverTimestamp();
    await _activityCollection.doc(activity.id).set(json);
  }

  @override
  Future<void> deleteRemoteActivity(String activityLogId) async {
    await _activityCollection.doc(activityLogId).delete();
  }
}
