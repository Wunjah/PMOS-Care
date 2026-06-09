import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/medication/domain/entities/medication_entity.dart';
import '../../features/providers/domain/entities/appointment_entity.dart';

@pragma('pragma:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background messaging handler triggered for ID: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late final FlutterLocalNotificationsPlugin _localNotifications;
  FirebaseMessaging? _fcm;
  FirebaseFirestore? _firestore;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _localNotifications = FlutterLocalNotificationsPlugin();

    // Check if Firebase is initialized before accessing FCM and Firestore
    try {
      _fcm = FirebaseMessaging.instance;
      _firestore = FirebaseFirestore.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'pmos_care_high_channel',
                'High Importance Notifications',
                channelDescription: 'Notifications regarding your hormone levels, cycle updates and treatments.',
                importance: Importance.max,
                priority: Priority.high,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          ).catchError((_) {});
        }
      });

      // Request permissions for background push notifications
      await _fcm?.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      print('Firebase messaging not initialized in NotificationService (expected in unit tests): $e');
    }

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Douala'));
    } catch (_) {}

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );
    } catch (e) {
      print('Local notification plugin failed to initialize: $e');
    }

    _initialized = true;
  }

  Future<void> registerFcmToken(String userId) async {
    if (_fcm == null || _firestore == null) return;
    try {
      final token = await _fcm!.getToken();
      if (token != null) {
        await _firestore!.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'clientUpdatedTimestamp': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error registering FCM Token: $e');
    }
  }

  Future<void> unregisterFcmToken(String userId) async {
    if (_fcm == null || _firestore == null) return;
    try {
      final token = await _fcm!.getToken();
      if (token != null) {
        await _firestore!.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleMedicationReminder(MedicationEntity med) async {
    if (!_initialized) await initialize();

    int hour = 8;
    int minute = 0;

    switch (med.timing.toLowerCase()) {
      case 'breakfast':
        hour = 8;
        break;
      case 'lunch':
        hour = 13;
        break;
      case 'dinner':
        hour = 19;
        break;
      case 'bedtime':
        hour = 22;
        break;
    }

    final int notificationId = med.id.hashCode;

    try {
      await _localNotifications.zonedSchedule(
        notificationId,
        'Medication Reminder: ${med.name}',
        'Time to take your scheduled dosage: ${med.dosage}',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pmos_med_channel',
            'Medication Reminders',
            channelDescription: 'Daily alerts to help you stay compliant with your hormonal treatments.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Skipping scheduled local notification in test/unsupported environment: $e');
    }
  }

  Future<void> cancelMedicationReminder(String medId) async {
    if (!_initialized) await initialize();
    try {
      await _localNotifications.cancel(medId.hashCode);
    } catch (e) {
      print('Skipping local notification cancellation in test/unsupported environment: $e');
    }
  }

  Future<void> scheduleAppointmentReminder(AppointmentEntity app) async {
    if (!_initialized) await initialize();

    final scheduledDate = tz.TZDateTime.from(app.dateTime.subtract(const Duration(hours: 1)), tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _localNotifications.zonedSchedule(
        app.id.hashCode,
        'Upcoming Specialist Consultation',
        'Reminder: You have a scheduled ${app.consultationType} with ${app.specialistName} in 1 hour.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pmos_appointment_channel',
            'Appointment Reminders',
            channelDescription: 'Alerts regarding upcoming appointments and consults.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Skipping scheduled local notification in test/unsupported environment: $e');
    }
  }

  Future<void> cancelAppointmentReminder(String appId) async {
    if (!_initialized) await initialize();
    try {
      await _localNotifications.cancel(appId.hashCode);
    } catch (e) {
      print('Skipping local notification cancellation in test/unsupported environment: $e');
    }
  }
}
