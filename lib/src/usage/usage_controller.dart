import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsageController extends ChangeNotifier with WidgetsBindingObserver {
  static const _keyLastIn = 'usage.last_in_iso.v1';
  static const _keyLastOut = 'usage.last_out_iso.v1';

  bool _initialized = false;
  bool get initialized => _initialized;

  DateTime? _lastIn;
  DateTime? get lastIn => _lastIn;

  DateTime? _lastOut;
  DateTime? get lastOut => _lastOut;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawIn = prefs.getString(_keyLastIn);
    final rawOut = prefs.getString(_keyLastOut);
    _lastIn = rawIn == null ? null : DateTime.tryParse(rawIn);
    _lastOut = rawOut == null ? null : DateTime.tryParse(rawOut);
    _initialized = true;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _markIn();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _markOut();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _markIn() async {
    final now = DateTime.now();
    _lastIn = now;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastIn, now.toIso8601String());
  }

  Future<void> _markOut() async {
    final now = DateTime.now();
    _lastOut = now;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastOut, now.toIso8601String());
  }
}
