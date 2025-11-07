import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/item.dart';
import '../data/models/saved_filter_adv.dart';
import '../data/models/saved_search.dart';
import 'items_controller.dart';

const _savedSearchesKey = 'saved_searches.json';
const _recentSearchesKey = 'recent.searches';
const _savedFiltersAdvKey = 'advanced_filters.json';

class SearchController {
  SearchController._(this._prefs, this._itemsController) {
    _resultsNotifier = ValueNotifier<List<Item>>(<Item>[]);
    _loadingNotifier = ValueNotifier<bool>(false);
    _savedSearchesNotifier = ValueNotifier<List<SavedSearch>>(<SavedSearch>[]);
    _recentQueriesNotifier = ValueNotifier<List<String>>(<String>[]);
    _advancedFiltersNotifier =
        ValueNotifier<List<SavedFilterAdv>>(<SavedFilterAdv>[]);
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
  late final ValueNotifier<List<SavedFilterAdv>> _advancedFiltersNotifier;
  List<Item> _matched = <Item>[];
  int _page = 0;
  static const int _pageSize = 12;
  String _currentQuery = '';
  SavedSearchFilters _currentFilters = const SavedSearchFilters();
  String _sortMode = 'relevance';
  Map<String, Set<String>> _invertedIndex = <String, Set<String>>{};

  ValueListenable<List<Item>> get resultsListenable => _resultsNotifier;
  ValueListenable<bool> get loadingListenable => _loadingNotifier;
  ValueListenable<List<SavedSearch>> get savedSearchesListenable =>
      _savedSearchesNotifier;
  ValueListenable<List<String>> get recentQueriesListenable =>
      _recentQueriesNotifier;
  ValueListenable<List<SavedFilterAdv>> get advancedFiltersListenable =>
      _advancedFiltersNotifier;

  Future<void> _load() async {
    final savedJson = _prefs.getString(_savedSearchesKey);
    final saved = <SavedSearch>[];
    if (savedJson != null && savedJson.isNotEmpty) {
      saved.addAll(SavedSearch.decodeList(savedJson));
      _savedSearchesNotifier.value = [...saved];
    }
    final recent = _prefs.getStringList(_recentSearchesKey) ?? <String>[];
    _recentQueriesNotifier.value = recent;
    final advanced = _prefs.getString(_savedFiltersAdvKey);
    if (advanced != null && advanced.isNotEmpty) {
      _advancedFiltersNotifier.value = SavedFilterAdv.decodeList(advanced);
    }
    if (_advancedFiltersNotifier.value.isEmpty && saved.isNotEmpty) {
      final migrated = saved
          .map(_convertSavedSearch)
          .whereType<SavedFilterAdv>()
          .toList();
      if (migrated.isNotEmpty) {
        _advancedFiltersNotifier.value = migrated;
        await _prefs
            .setString(_savedFiltersAdvKey, SavedFilterAdv.encodeList(migrated));
      }
    }
    _rebuildIndex();
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
    _rebuildIndex();
    final candidates = _candidatesForQuery(query);
    final baseResults = _itemsController.search(query);
    if (candidates != null && candidates.isNotEmpty) {
      _matched = _applyFilters(
        baseResults.where((item) => candidates.contains(item.id)).toList(),
      );
    } else {
      _matched = _applyFilters(baseResults);
    }
    _applySort();
    await _emitPage(reset: reset);
    _loadingNotifier.value = false;
    _trackRecentQuery(query);
  }

  Future<void> runAdvancedExpression(
    String expression, {
    bool reset = true,
  }) async {
    _loadingNotifier.value = true;
    if (reset) {
      _page = 0;
    }
    _currentQuery = expression;
    _currentFilters = const SavedSearchFilters();
    _sortMode = 'relevance';
    _matched = _itemsController.advancedFilter(expression);
    _applySort();
    await _emitPage(reset: reset);
    _loadingNotifier.value = false;
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

  Future<void> saveAdvancedFilter(SavedFilterAdv filter) async {
    final filters = [..._advancedFiltersNotifier.value];
    final index = filters.indexWhere((element) => element.id == filter.id);
    if (index == -1) {
      filters.add(filter);
    } else {
      filters[index] = filter;
    }
    _advancedFiltersNotifier.value = filters;
    await _prefs.setString(_savedFiltersAdvKey, SavedFilterAdv.encodeList(filters));
  }

  Future<void> deleteAdvancedFilter(String id) async {
    final filters =
        _advancedFiltersNotifier.value.where((element) => element.id != id).toList();
    _advancedFiltersNotifier.value = filters;
    await _prefs.setString(_savedFiltersAdvKey, SavedFilterAdv.encodeList(filters));
  }

  List<SavedFilterAdv> listAdvancedFilters() =>
      List<SavedFilterAdv>.unmodifiable(_advancedFiltersNotifier.value);

  Future<void> runSavedAdvancedFilter(SavedFilterAdv filter) async {
    await runAdvancedExpression(filter.expression, reset: true);
  }

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
    _advancedFiltersNotifier.dispose();
  }

  SavedFilterAdv? _convertSavedSearch(SavedSearch search) {
    final clauses = <String>[];
    final query = search.query.trim();
    if (query.isNotEmpty) {
      final escaped = _escape(query);
      clauses.add(
          '(name~"$escaped" OR description~"$escaped" OR tags~"$escaped")');
    }
    final filters = search.filters;
    if (filters.category != null && filters.category!.isNotEmpty) {
      clauses.add('category=="${_escape(filters.category!)}"');
    }
    if (filters.minPrice != null) {
      clauses.add('price>=${filters.minPrice}');
    }
    if (filters.maxPrice != null) {
      clauses.add('price<=${filters.maxPrice}');
    }
    if (filters.condition != null && filters.condition!.isNotEmpty) {
      clauses.add('condition=="${_escape(filters.condition!)}"');
    }
    if (filters.allowOffers != null) {
      clauses.add('allowOffers==${filters.allowOffers}');
    }
    if (clauses.isEmpty) {
      return null;
    }
    final expression = clauses.join(' AND ');
    return SavedFilterAdv(
      id: 'legacy_${search.id}',
      name: search.name,
      expression: expression,
      createdAt: DateTime.now(),
    );
  }

  String _escape(String input) {
    return input.replaceAll('"', '\\"');
  }

  void _rebuildIndex() {
    final Map<String, Set<String>> index = <String, Set<String>>{};
    for (final item in _itemsController.allItems) {
      final tokens = <String>{
        ...item.name.toLowerCase().split(RegExp(r'[\s,]+')),
        ...item.description.toLowerCase().split(RegExp(r'[\s,]+')),
        ...item.tags.map((tag) => tag.toLowerCase()),
      }..removeWhere((token) => token.isEmpty);
      for (final token in tokens) {
        index.update(token, (set) => set..add(item.id), ifAbsent: () => {item.id});
      }
    }
    _invertedIndex = index;
  }

  Set<String>? _candidatesForQuery(String query) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    if (terms.isEmpty) {
      return null;
    }
    final Set<String> combined = <String>{};
    for (final term in terms) {
      final matches = _invertedIndex[term];
      if (matches != null) {
        combined.addAll(matches);
      }
    }
    return combined.isEmpty ? null : combined;
  }
}
