import 'package:shared_preferences/shared_preferences.dart';

mixin PreferencesHandler {
  Future<void> saveStringList(String key, List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, list);
    } catch (e) {
      // Ignore errors when saving preferences
    }
  }

  Future<List<String>> loadStringList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> removeKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      // Ignore errors when removing preferences
    }
  }

  Future<void> saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', mode);
    } catch (e) {
      // Ignore errors when saving theme mode
    }
  }

  Future<String> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('theme_mode') ?? 'system';
    } catch (e) {
      return 'system';
    }
  }

  Future<void> saveScrollOffset(double offset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('scroll_offset', offset);
    } catch (e) {
      // Ignore errors when saving scroll offset
    }
  }

  Future<double> loadScrollOffset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('scroll_offset') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Ignore errors when saving preferences
    }
  }

  Future<bool> loadBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}
