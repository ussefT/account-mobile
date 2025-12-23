import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  static const _keyThemeMode = 'settings.theme_mode.v1';
  static const _keyTextScale = 'settings.text_scale.v1';
  static const _keyLocale = 'settings.locale.v1';

  bool _initialized = false;
  bool get initialized => _initialized;

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  Locale? _locale;
  Locale? get locale => _locale;

  double _textScale = 1.0;
  double get textScale => _textScale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTheme = prefs.getString(_keyThemeMode);
    _themeMode = rawTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final rawLocale = prefs.getString(_keyLocale);
    if (rawLocale != null) {
      _locale = Locale(rawLocale);
    } else {
      // If no locale is saved, let the app use the system locale by keeping _locale null
      // or we can explicitly detect it here. But usually leaving it null in MaterialApp
      // allows it to resolve to system locale.
      // However, if we want to enforce 'en' or 'fa' as default if system is something else:
      // For now, let's default to system if supported, or 'en'.
      
      // But we need to expose a non-null locale to the UI if possible, or handle null in UI.
      // The current UI expects a non-null locale for the dropdown.
      
      // Let's try to detect system locale.
      // Since we can't easily access system locale context here without context,
      // we will leave it null and let the UI handle it or default to 'en'.
      // Wait, the requirement is "Detect language os and change language to defualt system".
      
      // If I leave _locale as null, I need to update the UI to handle it.
      // But simpler is to set a default here if null.
      
      // Let's check PlatformDispatcher (available in Flutter 3.10+)
      try {
        final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
        if (systemLocales.isNotEmpty) {
          final systemLocale = systemLocales.first;
          if (systemLocale.languageCode == 'fa') {
            _locale = const Locale('fa');
          } else {
            _locale = const Locale('en');
          }
        } else {
          _locale = const Locale('en');
        }
      } catch (_) {
        _locale = const Locale('en');
      }
    }

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

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale.languageCode);
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

