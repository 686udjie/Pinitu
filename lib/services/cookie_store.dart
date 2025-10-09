import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CookieStore {
  static const _secureStorage = FlutterSecureStorage();
  static const String _cookiesKey = 'pinterest_cookies';

  static Future<List<Map<String, dynamic>>> readCookies() async {
    final cookiesJson = await _secureStorage.read(key: _cookiesKey);
    if (cookiesJson == null || cookiesJson.isEmpty) return <Map<String, dynamic>>[];
    final List<dynamic> list = jsonDecode(cookiesJson) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

// TO DO: add better cookie storing so that stability isnt an issue
// note: all personal usecases suceeded but improvments are needed
  static Future<String?> buildCookieHeader() async {
    final cookies = await readCookies();
    if (cookies.isEmpty) return null;
    // Join as name=value; name2=value2
    final parts = <String>[];
    for (final c in cookies) {
      final name = c['name']?.toString();
      final value = c['value']?.toString();
      if (name != null && value != null) {
        parts.add('$name=$value');
      }
    }
    if (parts.isEmpty) return null;
    return parts.join('; ');
  }
}
// TODO: Improve caching and add preload req logic 
// to reduce load times when switching betwen tabs or scrolling 
// for new images.
