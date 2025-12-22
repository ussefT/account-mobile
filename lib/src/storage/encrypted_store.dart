import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptedStore {
  EncryptedStore({
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
    required SecretKey secretKey,
  }) : _prefs = sharedPreferences,
       _secureStorage = secureStorage,
       _secretKey = secretKey;

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final SecretKey _secretKey;

  static const _keyMaterialKey = 'data.encryption_key.v1';
  static const _prefix = 'enc:v1';
  static const _separator = ':';

  static Future<EncryptedStore> create({
    SharedPreferences? sharedPreferences,
    FlutterSecureStorage? secureStorage,
  }) async {
    final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    final ss = secureStorage ?? const FlutterSecureStorage();

    var rawKey = await ss.read(key: _keyMaterialKey);
    if (rawKey == null || rawKey.isEmpty) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      rawKey = base64Encode(bytes);
      await ss.write(key: _keyMaterialKey, value: rawKey);
    }

    final keyBytes = base64Decode(rawKey);
    final key = SecretKey(keyBytes);

    return EncryptedStore(
      sharedPreferences: prefs,
      secureStorage: ss,
      secretKey: key,
    );
  }

  Future<String?> readString(String key) async {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    if (!raw.startsWith(_prefix)) {
      await writeString(key, raw);
      return raw;
    }

    final parts = raw.split(_separator);
    if (parts.length != 5) {
      throw const FormatException('Invalid encrypted data');
    }

    final nonce = base64Decode(parts[2]);
    final cipherText = base64Decode(parts[3]);
    final macBytes = base64Decode(parts[4]);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

    final algorithm = AesGcm.with256bits();
    final clearTextBytes = await algorithm.decrypt(
      secretBox,
      secretKey: _secretKey,
    );
    return utf8.decode(clearTextBytes);
  }

  Future<void> writeString(String key, String value) async {
    final algorithm = AesGcm.with256bits();
    final nonce = List<int>.generate(12, (_) => Random.secure().nextInt(256));
    final secretBox = await algorithm.encrypt(
      utf8.encode(value),
      secretKey: _secretKey,
      nonce: nonce,
    );

    final stored =
        '$_prefix$_separator${base64Encode(secretBox.nonce)}$_separator${base64Encode(secretBox.cipherText)}$_separator${base64Encode(secretBox.mac.bytes)}';
    await _prefs.setString(key, stored);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAllData() async {
    await _secureStorage.delete(key: _keyMaterialKey);
    await _prefs.clear();
  }
}
