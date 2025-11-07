import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/item.dart';
import '../data/models/saved_search.dart';
import 'items_controller.dart';

const _savedSearchesKey = 'saved_searches.json';
const _recentSearchesKey = 'recent.searches';

class SearchController {
  SearchController._(this._prefs, this._itemsController) {
    _resultsNotifier = ValueNotifier<List<Item>>(<Item>[]);
    _loadingNotifier = ValueNotifier<bool>(false);
    _savedSearchesNotifier = ValueNotifier<List<SavedSearch>>(<SavedSearch>[]);
    _recentQueriesNotifier = ValueNotifier<List<String>>(<String>[]);
  }

  static Future<SearchController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = SearchController._(prefs, itemsController);
    await controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;

  late final ValueNotifier<List<Item>> _resultsNotifier;
  late final ValueNotifier<bool> _loadingNotifier;
  late final ValueNotifier<List<SavedSearch>> _savedSearchesNotifier;
  late final ValueNotifier<List<String>> _recentQueriesNotifier;
  List<Item> _matched = <Item>[];
  int _page = 0;
  static const int _pageSize = 12;
  String _currentQuery = '';
  SavedSearchFilters _currentFilters = const SavedSearchFilters();
  String _sortMode = 'relevance';

  ValueListenable<List<Item>> get resultsListenable => _resultsNotifier;
  ValueListenable<bool> get loadingListenable => _loadingNotifier;
  ValueListenable<List<SavedSearch>> get savedSearchesListenable =>
      _savedSearchesNotifier;
  ValueListenable<List<String>> get recentQueriesListenable =>
      _recentQueriesNotifier;

  Future<void> _load() async {
    final savedJson = _prefs.getString(_savedSearchesKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      _savedSearchesNotifier.value = SavedSearch.decodeList(savedJson);
    }
    final recent = _prefs.getStringList(_recentSearchesKey) ?? <String>[];
    _recentQueriesNotifier.value = recent;
  }

  Future<void> run(
    String query, {
    SavedSearchFilters? filters,
    String sortMode = 'relevance',
    bool reset = true,
  }) async {
    _loadingNotifier.value = true;
    if (reset) {
      _page = 0;
    }
    _currentQuery = query;
    _currentFilters = filters ?? const SavedSearchFilters();
    _sortMode = sortMode;
    _matched = _applyFilters(_itemsController.search(query));
    _applySort();
    await _emitPage(reset: reset);
    _loadingNotifier.value = false;
    _trackRecentQuery(query);
  }

  Future<void> fetchNextPage() async {
    if (_loadingNotifier.value) return;
    if ((_page + 1) * _pageSize >= _matched.length) return;
    _page += 1;
    await _emitPage(reset: false);
  }

  List<Item> _applyFilters(List<Item> items) {
    return items.where((item) {
      if (_currentFilters.category != null &&
          _currentFilters.category!.isNotEmpty &&
          item.category != _currentFilters.category) {
        return false;
      }
      final price = item.price;
      if (_currentFilters.minPrice != null && price != null) {
        if (price < _currentFilters.minPrice!) return false;
      }
      if (_currentFilters.maxPrice != null && price != null) {
        if (price > _currentFilters.maxPrice!) return false;
      }
      if (_currentFilters.condition != null &&
          _currentFilters.condition!.isNotEmpty &&
          item.condition != _currentFilters.condition) {
        return false;
      }
      if (_currentFilters.allowOffers != null &&
          item.allowOffers != _currentFilters.allowOffers) {
        return false;
      }
      return true;
    }).toList();
  }

  void _applySort() {
    switch (_sortMode) {
      case 'priceAsc':
        _matched.sort((a, b) => (a.price ?? double.infinity)
            .compareTo(b.price ?? double.infinity));
        break;
      case 'priceDesc':
        _matched.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'newest':
        _matched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        break;
    }
  }

  Future<void> _emitPage({required bool reset}) async {
    final start = _page * _pageSize;
    final end = (_page + 1) * _pageSize;
    if (start >= _matched.length) {
      return;
    }
    final slice = _matched.sublist(
      start,
      end > _matched.length ? _matched.length : end,
    );
    if (reset) {
      _resultsNotifier.value = slice;
    } else {
      _resultsNotifier.value = [..._resultsNotifier.value, ...slice];
    }
  }

  Future<void> saveSearch(SavedSearch search) async {
    final searches = [..._savedSearchesNotifier.value];
    final index = searches.indexWhere((element) => element.id == search.id);
    if (index == -1) {
      searches.add(search);
    } else {
      searches[index] = search;
    }
    _savedSearchesNotifier.value = searches;
    await _prefs.setString(_savedSearchesKey, SavedSearch.encodeList(searches));
  }

  Future<void> saveCurrentQueryAs({required String id, required String name}) async {
    final search = SavedSearch(
      id: id,
      name: name,
      query: _currentQuery,
      filters: _currentFilters,
      createdAt: DateTime.now(),
    );
    await saveSearch(search);
  }

  Future<void> deleteSavedSearch(String id) async {
    final searches =
        _savedSearchesNotifier.value.where((element) => element.id != id).toList();
    _savedSearchesNotifier.value = searches;
    await _prefs.setString(_savedSearchesKey, SavedSearch.encodeList(searches));
  }

  List<SavedSearch> listSavedSearches() =>
      List<SavedSearch>.unmodifiable(_savedSearchesNotifier.value);

  void _trackRecentQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final recent = [..._recentQueriesNotifier.value];
    recent.remove(trimmed);
    recent.insert(0, trimmed);
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }
    _recentQueriesNotifier.value = recent;
    _prefs.setStringList(_recentSearchesKey, recent);
  }

  void dispose() {
    _resultsNotifier.dispose();
    _loadingNotifier.dispose();
    _savedSearchesNotifier.dispose();
    _recentQueriesNotifier.dispose();
  }
}
