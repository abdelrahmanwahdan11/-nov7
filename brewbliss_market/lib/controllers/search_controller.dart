import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/pagination_mixin.dart';
import '../data/models/item.dart';
import '../data/models/saved_search.dart';
import 'items_controller.dart';

const _savedSearchesKey = 'saved_searches.json';
const _recentSearchesKey = 'recent.searches';

class SearchController with PaginationMixin {
  SearchController._(this._prefs, this._itemsController) {
    _resultsNotifier = ValueNotifier<List<Item>>(<Item>[]);
    _loadingNotifier = ValueNotifier<bool>(false);
    _recentQueriesNotifier = ValueNotifier<List<String>>(<String>[]);
    _savedSearchesNotifier = ValueNotifier<List<SavedSearch>>(<SavedSearch>[]);
  }

  static Future<SearchController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = SearchController._(prefs, itemsController);
    controller
      .._loadSavedSearches()
      .._loadRecentQueries();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;
  late final ValueNotifier<List<Item>> _resultsNotifier;
  late final ValueNotifier<bool> _loadingNotifier;
  late final ValueNotifier<List<String>> _recentQueriesNotifier;
  late final ValueNotifier<List<SavedSearch>> _savedSearchesNotifier;
  List<Item> _matches = <Item>[];
  int _currentPage = 0;
  bool _isPaginating = false;

  ValueListenable<List<Item>> get resultsListenable => _resultsNotifier;
  ValueListenable<bool> get loadingListenable => _loadingNotifier;
  ValueListenable<List<String>> get recentQueriesListenable =>
      _recentQueriesNotifier;
  ValueListenable<List<SavedSearch>> get savedSearchesListenable =>
      _savedSearchesNotifier;

  List<SavedSearch> get savedSearches => _savedSearchesNotifier.value;

  Future<void> run(
    String query, {
    FilterOptions filters = const FilterOptions(),
    SortMode sort = SortMode.newest,
  }) async {
    _loadingNotifier.value = true;
    _currentPage = 0;
    _resultsNotifier.value = <Item>[];

    final trimmed = query.trim();
    _storeRecent(trimmed);

    Iterable<Item> working = _itemsController.allItems;
    if (filters.hasFilters) {
      working = working.where(filters.matches);
    }

    final List<Item> ranked;
    if (trimmed.isEmpty) {
      ranked = working.toList();
    } else {
      ranked = _rankedSearch(working, trimmed);
    }
    _matches = _sort(ranked, sort);

    await paginate(reset: true);
    _loadingNotifier.value = false;
  }

  Future<void> paginate({bool reset = false}) async {
    if (_isPaginating) {
      return;
    }
    if (reset) {
      _currentPage = 0;
      _resultsNotifier.value = <Item>[];
    }
    if (isEnd(_currentPage, _matches.length)) {
      _loadingNotifier.value = false;
      return;
    }
    _isPaginating = true;
    _loadingNotifier.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final slice = sliceForPage<Item>(_matches, _currentPage);
    if (slice.isNotEmpty) {
      _currentPage += 1;
      _resultsNotifier.value = <Item>[..._resultsNotifier.value, ...slice];
    }
    _loadingNotifier.value = false;
    _isPaginating = false;
  }

  Future<void> saveSearch(SavedSearch search) async {
    final searches = <SavedSearch>[..._savedSearchesNotifier.value];
    final index = searches.indexWhere((element) => element.id == search.id);
    if (index == -1) {
      searches.insert(0, search);
    } else {
      searches[index] = search;
    }
    _savedSearchesNotifier.value = List<SavedSearch>.unmodifiable(searches);
    await _prefs.setString(
      _savedSearchesKey,
      SavedSearch.encodeList(_savedSearchesNotifier.value),
    );
  }

  Future<void> deleteSavedSearch(String id) async {
    final searches =
        _savedSearchesNotifier.value.where((search) => search.id != id).toList();
    _savedSearchesNotifier.value = List<SavedSearch>.unmodifiable(searches);
    await _prefs.setString(
      _savedSearchesKey,
      SavedSearch.encodeList(_savedSearchesNotifier.value),
    );
  }

  void _loadSavedSearches() {
    final json = _prefs.getString(_savedSearchesKey);
    if (json != null && json.isNotEmpty) {
      _savedSearchesNotifier.value =
          List<SavedSearch>.unmodifiable(SavedSearch.decodeList(json));
    }
  }

  void _loadRecentQueries() {
    final list = _prefs.getStringList(_recentSearchesKey) ?? <String>[];
    _recentQueriesNotifier.value = List<String>.unmodifiable(list);
  }

  void _storeRecent(String query) {
    if (query.isEmpty) {
      return;
    }
    final current = <String>[..._recentQueriesNotifier.value];
    current.remove(query);
    current.insert(0, query);
    if (current.length > 8) {
      current.removeRange(8, current.length);
    }
    _recentQueriesNotifier.value = List<String>.unmodifiable(current);
    _prefs.setStringList(_recentSearchesKey, current);
  }

  List<Item> _rankedSearch(Iterable<Item> source, String query) {
    final q = query.toLowerCase();
    final results = <_SearchScore>[];
    for (final item in source) {
      int score = 0;
      if (item.name.toLowerCase().contains(q)) {
        score += 8;
      }
      if (item.description.toLowerCase().contains(q)) {
        score += 4;
      }
      if (item.tags.any((tag) => tag.toLowerCase().contains(q))) {
        score += 3;
      }
      if (item.category.toLowerCase().contains(q)) {
        score += 2;
      }
      if (item.attrs.values
          .any((value) => value.toLowerCase().contains(q))) {
        score += 1;
      }
      if (score > 0) {
        results.add(_SearchScore(item, score));
      }
    }
    results.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) {
        return cmp;
      }
      return b.item.createdAt.compareTo(a.item.createdAt);
    });
    return results.map((e) => e.item).toList();
  }

  List<Item> _sort(List<Item> items, SortMode sortMode) {
    final sorted = List<Item>.from(items);
    switch (sortMode) {
      case SortMode.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.priceLowToHigh:
        sorted.sort((a, b) => (a.price ?? double.infinity)
            .compareTo(b.price ?? double.infinity));
        break;
      case SortMode.priceHighToLow:
        sorted.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
    }
    return sorted;
  }

  void dispose() {
    _resultsNotifier.dispose();
    _loadingNotifier.dispose();
    _recentQueriesNotifier.dispose();
    _savedSearchesNotifier.dispose();
  }
}

class _SearchScore {
  const _SearchScore(this.item, this.score);

  final Item item;
  final int score;
}
