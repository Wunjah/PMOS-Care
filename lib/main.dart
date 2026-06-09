import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/notifications/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications & channels
  await NotificationService().initialize();

  await Hive.initFlutter();
  await Hive.openBox('pmos_cycle_storage_box');
  await Hive.openBox('pmos_symptom_box');
  await Hive.openBox('pmos_weight_box');
  await Hive.openBox('pmos_activity_box');
  await Hive.openBox('pmos_medication_box');
  await Hive.openBox('pmos_appointment_box');
  await Hive.openBox('pmos_diet_box');

  runApp(
    const ProviderScope(
      child: PMOSCareApp(),
    ),
  );
}
