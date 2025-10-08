import 'package:shared_preferences/shared_preferences.dart';

mixin PreferencesHandler {
  Future<void> saveStringList(String key, List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, list);
    } catch (e) {}
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
    } catch (e) {}
  }
}
