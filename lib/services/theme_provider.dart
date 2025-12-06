import 'package:flutter/material.dart';
import 'preferences_handler.dart';

class ThemeProvider with ChangeNotifier, PreferencesHandler {
  ThemeMode _themeMode = ThemeMode.system;
  bool _hideNavbarLabels = false;

  ThemeMode get themeMode => _themeMode;
  bool get hideNavbarLabels => _hideNavbarLabels;

  ThemeProvider() {
    _loadThemeMode();
    _loadHideNavbarLabels();
  }

  Future<void> _loadThemeMode() async {
    final mode = await loadThemeMode();
    switch (mode) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> _loadHideNavbarLabels() async {
    _hideNavbarLabels = await loadBool('hide_navbar_labels');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    await saveThemeMode(modeStr);
    notifyListeners();
  }

  Future<void> setHideNavbarLabels(bool value) async {
    _hideNavbarLabels = value;
    await saveBool('hide_navbar_labels', value);
    notifyListeners();
  }
}
