import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class StorageService {
  Box getHiveBox(String name) {
    return Hive.box(name);
  }

  Future<Box> initHiveBox(String name) async {
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

    var k = await secureStorage.read(key: 'key');

    var encryptionKey = base64Url.decode(k!);

    return await Hive.openBox(
      name,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future initHiveStorage() async {
    final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
    var containsEncryptionKey = await secureStorage.containsKey(key: 'key');
    if (!containsEncryptionKey) {
      // Generate a secure 32-byte key
      final secureRandom = Random.secure();
      final key = Uint8List.fromList(
        List<int>.generate(32, (_) => secureRandom.nextInt(256)),
      );
      await secureStorage.write(key: 'key', value: base64UrlEncode(key));
    }
    return await Hive.initFlutter();
  }

  putSharedPrefBoolValue(String key, bool value) async {
    var _prefs = await SharedPreferences.getInstance();
    await _prefs.setBool(key, value);
  }

  Future<bool?> getSharedPrefBoolValue(String key) async {
    var _prefs = await SharedPreferences.getInstance();
    await _prefs.reload();
    return _prefs.getBool(key);
  }
}
