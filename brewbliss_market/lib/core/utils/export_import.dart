import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ExportImport {
  const ExportImport._();

  static Future<String> exportPrefs(
      SharedPreferences prefs, List<String> keys) async {
    final snapshot = <String, dynamic>{};
    for (final key in keys) {
      final value = prefs.get(key);
      if (value == null) {
        continue;
      }
      if (value is List<String>) {
        snapshot[key] = value;
      } else if (value is bool || value is num || value is String) {
        snapshot[key] = value;
      } else {
        snapshot[key] = value.toString();
      }
    }
    return jsonEncode(snapshot);
  }

  static Future<void> importPrefs(
    SharedPreferences prefs,
    String rawJson,
  ) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid export payload');
    }
    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        final list = value.map((element) => '$element').toList();
        await prefs.setStringList(key, list);
      }
    }
  }
}
