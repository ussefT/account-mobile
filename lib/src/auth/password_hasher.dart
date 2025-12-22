import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHash {
  const PasswordHash({
    required this.saltBase64,
    required this.hashBase64,
  });

  final String saltBase64;
  final String hashBase64;
}

class PasswordHasher {
  static PasswordHash create(String password) {
    final saltBytes = _randomBytes(16);
    final hashBytes = _hash(saltBytes, password);

    return PasswordHash(
      saltBase64: base64Encode(saltBytes),
      hashBase64: base64Encode(hashBytes),
    );
  }

  static bool verify({
    required String password,
    required String saltBase64,
    required String expectedHashBase64,
  }) {
    final saltBytes = base64Decode(saltBase64);
    final expectedHashBytes = base64Decode(expectedHashBase64);
    final actualHashBytes = _hash(saltBytes, password);
    return _constantTimeEquals(actualHashBytes, expectedHashBytes);
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int> _hash(List<int> saltBytes, String password) {
    final passwordBytes = utf8.encode(password);
    final digest = sha256.convert(<int>[...saltBytes, ...passwordBytes]);
    return digest.bytes;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

