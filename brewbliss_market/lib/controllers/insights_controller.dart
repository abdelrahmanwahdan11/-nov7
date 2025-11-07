import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _insightsKey = 'insights.json';

class InsightsSnapshot {
  const InsightsSnapshot({
    required this.views,
    required this.favorites,
    required this.addToCart,
    required this.compares,
    required this.searchTerms,
  });

  final Map<String, int> views;
  final Map<String, int> favorites;
  final Map<String, int> addToCart;
  final Map<String, int> compares;
  final Map<String, int> searchTerms;
}

class InsightsController extends ChangeNotifier {
  InsightsController._(this._prefs);

  static Future<InsightsController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = InsightsController._(prefs);
    controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  final Map<String, int> _views = {};
  final Map<String, int> _favorites = {};
  final Map<String, int> _addToCart = {};
  final Map<String, int> _compares = {};
  final Map<String, int> _searchTerms = {};

  InsightsSnapshot get snapshot => InsightsSnapshot(
        views: Map.unmodifiable(_views),
        favorites: Map.unmodifiable(_favorites),
        addToCart: Map.unmodifiable(_addToCart),
        compares: Map.unmodifiable(_compares),
        searchTerms: Map.unmodifiable(_searchTerms),
      );

  void logView(String itemId) {
    _views[itemId] = (_views[itemId] ?? 0) + 1;
    _persist();
  }

  void logFavorite(String itemId) {
    _favorites[itemId] = (_favorites[itemId] ?? 0) + 1;
    _persist();
  }

  void logAddToCart(String itemId) {
    _addToCart[itemId] = (_addToCart[itemId] ?? 0) + 1;
    _persist();
  }

  void logCompare(String itemId) {
    _compares[itemId] = (_compares[itemId] ?? 0) + 1;
    _persist();
  }

  void logSearch(String query) {
    if (query.isEmpty) return;
    _searchTerms[query] = (_searchTerms[query] ?? 0) + 1;
    _persist();
  }

  void reset() {
    _views.clear();
    _favorites.clear();
    _addToCart.clear();
    _compares.clear();
    _searchTerms.clear();
    _persist();
  }

  void _load() {
    final json = _prefs.getString(_insightsKey);
    if (json == null || json.isEmpty) return;
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    void parse(Map<String, int> target, String key) {
      final data = decoded[key] as Map<String, dynamic>?;
      if (data == null) return;
      target
        ..clear()
        ..addAll(data.map((k, v) => MapEntry(k, (v as num).toInt())));
    }

    parse(_views, 'views');
    parse(_favorites, 'favorites');
    parse(_addToCart, 'cart');
    parse(_compares, 'compares');
    parse(_searchTerms, 'search');
  }

  void _persist() {
    final payload = <String, dynamic>{
      'views': _views,
      'favorites': _favorites,
      'cart': _addToCart,
      'compares': _compares,
      'search': _searchTerms,
    };
    _prefs.setString(_insightsKey, jsonEncode(payload));
    notifyListeners();
  }
}
