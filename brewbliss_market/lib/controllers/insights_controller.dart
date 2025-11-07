import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'items_controller.dart';

const _insightsKey = 'insights.json';

class InsightsController {
  InsightsController._(this._prefs, this._itemsController) {
    _snapshotNotifier = ValueNotifier<InsightsSnapshot>(InsightsSnapshot.empty());
  }

  static Future<InsightsController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = InsightsController._(prefs, itemsController);
    await controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;
  late final ValueNotifier<InsightsSnapshot> _snapshotNotifier;

  ValueListenable<InsightsSnapshot> get snapshotListenable => _snapshotNotifier;

  Future<void> _load() async {
    final json = _prefs.getString(_insightsKey);
    if (json != null && json.isNotEmpty) {
      _snapshotNotifier.value = InsightsSnapshot.fromJson(json);
    } else {
      _snapshotNotifier.value = InsightsSnapshot.empty();
    }
  }

  void recordEvent(String type, String itemId) {
    final snapshot = _snapshotNotifier.value.copy();
    switch (type) {
      case 'view':
        snapshot.views[itemId] = (snapshot.views[itemId] ?? 0) + 1;
        break;
      case 'favorite':
        snapshot.favorites[itemId] = (snapshot.favorites[itemId] ?? 0) + 1;
        break;
      case 'cart':
        snapshot.addToCart[itemId] = (snapshot.addToCart[itemId] ?? 0) + 1;
        break;
      case 'compare':
        snapshot.compares[itemId] = (snapshot.compares[itemId] ?? 0) + 1;
        break;
      case 'negotiation':
        snapshot.negotiations[itemId] = (snapshot.negotiations[itemId] ?? 0) + 1;
        break;
      case 'search':
        snapshot.searchQueries[itemId] = (snapshot.searchQueries[itemId] ?? 0) + 1;
        break;
      default:
        break;
    }
    _snapshotNotifier.value = snapshot.copy();
    _persist();
  }

  void refreshFromItems() {
    final snapshot = _snapshotNotifier.value.copy();
    final items = _itemsController.allItems;
    snapshot.totals['items'] = items.length;
    snapshot.totals['offers'] = _itemsController.offersListenable.value.length;
    _snapshotNotifier.value = snapshot;
    _persist();
  }

  void clear() {
    _snapshotNotifier.value = InsightsSnapshot.empty();
    _prefs.remove(_insightsKey);
  }

  void dispose() {
    _snapshotNotifier.dispose();
  }

  void _persist() {
    _prefs.setString(_insightsKey, _snapshotNotifier.value.toJson());
  }
}

class InsightsSnapshot {
  InsightsSnapshot({
    required this.views,
    required this.favorites,
    required this.addToCart,
    required this.compares,
    required this.negotiations,
    required this.searchQueries,
    required this.totals,
  });

  factory InsightsSnapshot.empty() {
    return InsightsSnapshot(
      views: <String, int>{},
      favorites: <String, int>{},
      addToCart: <String, int>{},
      compares: <String, int>{},
      negotiations: <String, int>{},
      searchQueries: <String, int>{},
      totals: <String, int>{},
    );
  }

  factory InsightsSnapshot.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return InsightsSnapshot(
      views: _castMap(json['views']),
      favorites: _castMap(json['favorites']),
      addToCart: _castMap(json['addToCart']),
      compares: _castMap(json['compares']),
      negotiations: _castMap(json['negotiations']),
      searchQueries: _castMap(json['searchQueries']),
      totals: _castMap(json['totals']),
    );
  }

  final Map<String, int> views;
  final Map<String, int> favorites;
  final Map<String, int> addToCart;
  final Map<String, int> compares;
  final Map<String, int> negotiations;
  final Map<String, int> searchQueries;
  final Map<String, int> totals;

  InsightsSnapshot copy() {
    return InsightsSnapshot(
      views: Map<String, int>.from(views),
      favorites: Map<String, int>.from(favorites),
      addToCart: Map<String, int>.from(addToCart),
      compares: Map<String, int>.from(compares),
      negotiations: Map<String, int>.from(negotiations),
      searchQueries: Map<String, int>.from(searchQueries),
      totals: Map<String, int>.from(totals),
    );
  }

  String toJson() {
    return jsonEncode({
      'views': views,
      'favorites': favorites,
      'addToCart': addToCart,
      'compares': compares,
      'negotiations': negotiations,
      'searchQueries': searchQueries,
      'totals': totals,
    });
  }

  static Map<String, int> _castMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, dynamic v) => MapEntry(key, (v as num).toInt()));
    }
    return <String, int>{};
  }
}
