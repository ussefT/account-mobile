import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _keyThemeMode = 'settings.theme_mode.v1';
  static const _keyTextScale = 'settings.text_scale.v1';

  bool _initialized = false;
  bool get initialized => _initialized;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  double _textScale = 1.0;
  double get textScale => _textScale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTheme = prefs.getString(_keyThemeMode);
    _themeMode = rawTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final rawScale = prefs.getDouble(_keyTextScale);
    _textScale = (rawScale ?? 1.0).clamp(0.8, 1.6);

    _initialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setTextScale(double scale) async {
    final next = scale.clamp(0.8, 1.6);
    if ((_textScale - next).abs() < 0.001) return;
    _textScale = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTextScale, _textScale);
  }
}

