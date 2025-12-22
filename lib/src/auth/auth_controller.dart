import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_repository.dart';

class AuthController extends ChangeNotifier with WidgetsBindingObserver {
  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool _hasAccount = false;
  bool get hasAccount => _hasAccount;

  bool _authenticated = false;
  bool get authenticated => _authenticated;

  String? _username;
  String? get username => _username;

  Future<void> init() async {
    _hasAccount = await _authRepository.hasAccount();
    if (_hasAccount) {
      final creds = await _authRepository.readCredentials();
      _username = creds?.username;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> createAccount({
    required String username,
    required String password,
  }) async {
    await _authRepository.createAccount(username: username, password: password);
    _hasAccount = true;
    _authenticated = true;
    _username = username.trim();
    notifyListeners();
  }

  Future<bool> login({required String password}) async {
    final ok = await _authRepository.verifyPassword(password);
    if (!ok) return false;
    final creds = await _authRepository.readCredentials();
    _authenticated = true;
    _username = creds?.username;
    notifyListeners();
    return true;
  }

  Future<bool> biometricUnlock() async {
    if (!await _authRepository.hasAccount()) return false;
    if (!await _authRepository.biometricEnabled()) return false;

    final auth = LocalAuthentication();
    final supported = await auth.isDeviceSupported();
    if (!supported) return false;

    final ok = await auth.authenticate(
      localizedReason: 'Unlock your account',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    if (!ok) return false;

    final creds = await _authRepository.readCredentials();
    _authenticated = true;
    _username = creds?.username;
    notifyListeners();
    return true;
  }

  void lock() {
    if (!_authenticated) return;
    _authenticated = false;
    notifyListeners();
  }

  Future<void> logout() async {
    lock();
  }

  Future<void> resetAccount() async {
    await _authRepository.deleteAccount();
    _hasAccount = false;
    _authenticated = false;
    _username = null;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        lock();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }
}
