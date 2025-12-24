import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'password_hasher.dart';

class StoredCredentials {
  const StoredCredentials({
    required this.username,
    required this.saltBase64,
    required this.hashBase64,
  });

  final String username;
  final String saltBase64;
  final String hashBase64;
}

class AuthRepository {
  AuthRepository({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _keyUsername = 'account.username';
  static const _keySalt = 'account.password_salt';
  static const _keyHash = 'account.password_hash';
  static const _keyBiometricEnabled = 'account.biometric_enabled';
  static const _keyPasswordEnabled = 'account.password_enabled';

  Future<bool> hasAccount() async {
    final username = await _secureStorage.read(key: _keyUsername);
    return username != null;
  }

  Future<StoredCredentials?> readCredentials() async {
    final username = await _secureStorage.read(key: _keyUsername);
    final salt = await _secureStorage.read(key: _keySalt);
    final hash = await _secureStorage.read(key: _keyHash);
    if (username == null) return null;
    if (salt == null || hash == null) return null;
    return StoredCredentials(username: username, saltBase64: salt, hashBase64: hash);
  }

  Future<bool> passwordEnabled() async {
    final v = await _secureStorage.read(key: _keyPasswordEnabled);
    if (v == null) return true;
    return v.toLowerCase() != 'false';
  }

  Future<void> setPasswordEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyPasswordEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<void> createAccount({
    required String username,
    required String password,
    bool passwordEnabled = true,
  }) async {
    await _secureStorage.write(key: _keyUsername, value: username.trim());
    
    if (passwordEnabled && password.isNotEmpty) {
      final passwordHash = PasswordHasher.create(password);
      await _secureStorage.write(key: _keySalt, value: passwordHash.saltBase64);
      await _secureStorage.write(key: _keyHash, value: passwordHash.hashBase64);
    }
    
    await _secureStorage.write(key: _keyPasswordEnabled, value: passwordEnabled ? 'true' : 'false');
    await _secureStorage.write(key: _keyBiometricEnabled, value: 'true');
  }

  Future<bool> biometricEnabled() async {
    final v = await _secureStorage.read(key: _keyBiometricEnabled);
    if (v == null) return true;
    return v.toLowerCase() != 'false';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  Future<bool> verifyPassword(String password) async {
    final enabled = await passwordEnabled();
    if (!enabled) return true; // No password required
    
    final creds = await readCredentials();
    if (creds == null) return true; // No password set
    
    return PasswordHasher.verify(
      password: password,
      saltBase64: creds.saltBase64,
      expectedHashBase64: creds.hashBase64,
    );
  }

  Future<void> deleteAccount() async {
    await _secureStorage.delete(key: _keyUsername);
    await _secureStorage.delete(key: _keySalt);
    await _secureStorage.delete(key: _keyHash);
    await _secureStorage.delete(key: _keyBiometricEnabled);
    await _secureStorage.delete(key: _keyPasswordEnabled);
  }
}
