import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7d81WB54HBRevnkQfzCWNA1Q5AaG1Kbw',
    appId: '1:630482464919:web:5d04cd2a3e7f5302cd39d2',
    messagingSenderId: '630482464919',
    projectId: 'pmos-care',
    authDomain: 'pmos-care.firebaseapp.com',
    storageBucket: 'pmos-care.firebasestorage.app',
    measurementId: 'G-PSMW10ZP8K',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNpkebD77eRlfWHQ5h1wxjjFhyHw4hjyc',
    appId: '1:630482464919:android:2b4e1d5497163186cd39d2',
    messagingSenderId: '630482464919',
    projectId: 'pmos-care',
    storageBucket: 'pmos-care.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder-ios-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'pmos-care-placeholder',
    storageBucket: 'pmos-care-placeholder.appspot.com',
    iosBundleId: 'com.example.pmosCare',
  );
}
