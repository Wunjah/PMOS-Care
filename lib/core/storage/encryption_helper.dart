import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveEncryptionHelper {
  static const String _encryptionKeyName = 'pmos_hive_secret_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<HiveAesCipher> initializeSecureHive() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    final containsKey = await _secureStorage.containsKey(key: _encryptionKeyName);
    
    List<int> encryptionKey;
    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64UrlEncode(key),
      );
      encryptionKey = key;
    } else {
      final base64Key = await _secureStorage.read(key: _encryptionKeyName);
      encryptionKey = base64Url.decode(base64Key!);
    }

    return HiveAesCipher(encryptionKey);
  }

  static Future<Box<T>> openSecureBox<T>(String boxName, HiveAesCipher cipher) async {
    return await Hive.openBox<T>(
      boxName,
      encryptionCipher: cipher,
    );
  }
}
