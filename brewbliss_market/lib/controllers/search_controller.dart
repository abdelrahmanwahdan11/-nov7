import 'package:flutter/foundation.dart';

import '../data/models/item.dart';
import '../data/models/saved_search.dart';
import 'items_controller.dart';

class SearchController extends ChangeNotifier {
  SearchController({required this.itemsController}) {
    _resultsNotifier = ValueNotifier<List<Item>>([]);
    _savedSearchesNotifier = ValueNotifier<List<SavedSearch>>([]);
    itemsController.savedSearchesListenable.addListener(_syncSavedSearches);
    _syncSavedSearches();
  }

  final ItemsController itemsController;
  late final ValueNotifier<List<Item>> _resultsNotifier;
  late final ValueNotifier<List<SavedSearch>> _savedSearchesNotifier;
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> _recentQueriesNotifier =
      ValueNotifier<List<String>>([]);
  int _currentPage = 0;
  static const int _pageSize = 12;
  List<Item> _buffer = const [];
  String _lastQuery = '';
  Map<String, dynamic>? _lastFilters;

  ValueListenable<List<Item>> get resultsListenable => _resultsNotifier;
  ValueListenable<bool> get loadingListenable => _loadingNotifier;
  ValueListenable<List<SavedSearch>> get savedSearchesListenable =>
      _savedSearchesNotifier;
  ValueListenable<List<String>> get recentQueriesListenable =>
      _recentQueriesNotifier;

  Future<void> run(String query, {Map<String, dynamic>? filters}) async {
    _loadingNotifier.value = true;
    _lastQuery = query;
    _lastFilters = filters;
    final lower = query.trim();
    if (lower.isEmpty) {
      _buffer = [];
    } else {
      _buffer = itemsController.search(lower, filters: filters);
    }
    _currentPage = 0;
    _resultsNotifier.value = [];
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await paginate();
    _loadingNotifier.value = false;
    _trackQuery(lower);
  }

  Future<void> paginate() async {
    if (_currentPage * _pageSize >= _buffer.length) return;
    final next = _buffer.sublist(
      _currentPage * _pageSize,
      ((_currentPage + 1) * _pageSize).clamp(0, _buffer.length) as int,
    );
    _currentPage++;
    _resultsNotifier.value = [..._resultsNotifier.value, ...next];
  }

  Future<void> saveSearch(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final saved = SavedSearch(
      id: id,
      name: name,
      query: _lastQuery,
      filters: _lastFilters ?? {},
    );
    await itemsController.addSavedSearch(saved);
  }

  Future<void> deleteSavedSearch(String id) async {
    await itemsController.removeSavedSearch(id);
  }

  void _syncSavedSearches() {
    _savedSearchesNotifier.value = itemsController.savedSearchesListenable.value;
  }

  void _trackQuery(String query) {
    if (query.isEmpty) return;
    final recent = [..._recentQueriesNotifier.value];
    recent.remove(query);
    recent.insert(0, query);
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }
    _recentQueriesNotifier.value = recent;
  }

  @override
  void dispose() {
    itemsController.savedSearchesListenable.removeListener(_syncSavedSearches);
    _resultsNotifier.dispose();
    _savedSearchesNotifier.dispose();
    _loadingNotifier.dispose();
    _recentQueriesNotifier.dispose();
    super.dispose();
  }
}
