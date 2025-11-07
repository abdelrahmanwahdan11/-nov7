import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ExportImport {
  static const trackedKeys = <String>{
    'items.json',
    'favorites.ids',
    'compare.ids',
    'offers.json',
    'wishlist.ids',
    'collections.json',
    'reviews.json',
    'price_history.json',
    'saved_searches.json',
    'recent.searches',
    'price_alerts.json',
    'variant.selection',
    'interaction.metrics',
    'cart.json',
    'negotiations.json',
    'feature_flags.json',
    'export_dump.json',
    'prefs.lang',
    'prefs.dark',
    'prefs.primary',
    'firstLaunchDone',
    'coach.pending',
  };

  static Map<String, dynamic> buildSnapshot(SharedPreferences prefs) {
    final Map<String, dynamic> snapshot = {};
    for (final key in trackedKeys) {
      final value = prefs.get(key);
      if (value == null) continue;
      if (value is List<String>) {
        snapshot[key] = value;
      } else if (value is bool || value is int || value is double) {
        snapshot[key] = value;
      } else if (value is String) {
        snapshot[key] = value;
      }
    }
    return snapshot;
  }

  static Future<void> restore(
    SharedPreferences prefs,
    Map<String, dynamic> dump,
  ) async {
    for (final entry in dump.entries) {
      final key = entry.key;
      if (!trackedKeys.contains(key)) {
        continue;
      }
      final value = entry.value;
      if (value is List) {
        await prefs.setStringList(key, value.map((e) => '$e').toList());
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is num) {
        await prefs.setDouble(key, value.toDouble());
      } else if (value is String) {
        await prefs.setString(key, value);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    }
  }
}
