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
}
