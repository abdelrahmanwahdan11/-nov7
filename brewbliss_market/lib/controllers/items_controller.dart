import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/pagination_mixin.dart';
import '../data/local/seed.dart';
import '../data/models/item.dart';
import '../data/models/offer.dart';

const _itemsKey = 'items.json';
const _favoritesKey = 'favorites.ids';
const _compareKey = 'compare.ids';
const _offersKey = 'offers.json';

enum SortMode { newest, priceLowToHigh, priceHighToLow }

class FilterOptions {
  const FilterOptions({
    this.categories = const <String>{},
    this.conditions = const <String>{},
    this.minPrice,
    this.maxPrice,
    this.allowOffersOnly = false,
  });

  final Set<String> categories;
  final Set<String> conditions;
  final double? minPrice;
  final double? maxPrice;
  final bool allowOffersOnly;

  bool get hasFilters =>
      categories.isNotEmpty ||
      conditions.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      allowOffersOnly;

  FilterOptions copyWith({
    Set<String>? categories,
    Set<String>? conditions,
    double? minPrice,
    double? maxPrice,
    bool? allowOffersOnly,
  }) {
    return FilterOptions(
      categories: categories ?? this.categories,
      conditions: conditions ?? this.conditions,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      allowOffersOnly: allowOffersOnly ?? this.allowOffersOnly,
    );
  }

  bool matches(Item item) {
    if (categories.isNotEmpty && !categories.contains(item.category)) {
      return false;
    }
    if (conditions.isNotEmpty && !conditions.contains(item.condition)) {
      return false;
    }
    final price = item.price;
    if (minPrice != null) {
      if (price == null || price < minPrice!) return false;
    }
    if (maxPrice != null) {
      if (price == null || price > maxPrice!) return false;
    }
    if (allowOffersOnly && !item.allowOffers) {
      return false;
    }
    return true;
  }

  static FilterOptions empty() => const FilterOptions();
}

class ItemsController with PaginationMixin {
  ItemsController._(this._prefs) {
    _visibleItemsNotifier = ValueNotifier<List<Item>>(<Item>[]);
    _isLoadingNotifier = ValueNotifier<bool>(false);
    _favoritesNotifier = ValueNotifier<Set<String>>(<String>{});
    _compareNotifier = ValueNotifier<Set<String>>(<String>{});
    _offersNotifier = ValueNotifier<List<Offer>>(<Offer>[]);
    _offersBadgeNotifier = ValueNotifier<int>(0);
    _itemsStreamController = StreamController<List<Item>>.broadcast();
    _favoritesStreamController = StreamController<Set<String>>.broadcast();
    _compareStreamController = StreamController<Set<String>>.broadcast();
  }

  static Future<ItemsController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = ItemsController._(prefs);
    await controller.seed();
    controller.simulateIncomingOffers();
    return controller;
  }

  final SharedPreferences _prefs;
  late final ValueNotifier<List<Item>> _visibleItemsNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<Set<String>> _favoritesNotifier;
  late final ValueNotifier<Set<String>> _compareNotifier;
  late final ValueNotifier<List<Offer>> _offersNotifier;
  late final ValueNotifier<int> _offersBadgeNotifier;
  late final StreamController<List<Item>> _itemsStreamController;
  late final StreamController<Set<String>> _favoritesStreamController;
  late final StreamController<Set<String>> _compareStreamController;

  final Random _random = Random();
  Timer? _offerTimer;
  List<Item> _allItems = <Item>[];
  List<Item> _filteredItems = <Item>[];
  FilterOptions _filters = FilterOptions.empty();
  SortMode _sortMode = SortMode.newest;
  String _searchQuery = '';
  int _currentPage = 0;
  bool _isPaginating = false;

  ValueListenable<List<Item>> get visibleItemsListenable => _visibleItemsNotifier;
  ValueListenable<bool> get loadingListenable => _isLoadingNotifier;
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;
  ValueListenable<Set<String>> get compareListenable => _compareNotifier;
  ValueListenable<List<Offer>> get offersListenable => _offersNotifier;
  ValueListenable<int> get offersBadgeListenable => _offersBadgeNotifier;

  Stream<List<Item>> get itemsStream => _itemsStreamController.stream;
  Stream<Set<String>> get favoritesStream => _favoritesStreamController.stream;
  Stream<Set<String>> get compareStream => _compareStreamController.stream;

  FilterOptions get filters => _filters;
  SortMode get sortMode => _sortMode;
  String get searchQuery => _searchQuery;

  Future<void> seed() async {
    final itemsJson = _prefs.getString(_itemsKey);
    if (itemsJson != null && itemsJson.isNotEmpty) {
      _allItems = Item.decodeList(itemsJson);
    } else {
      _allItems = List<Item>.from(seedItems);
      await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    }

    final favIds = _prefs.getStringList(_favoritesKey) ?? <String>[];
    final compareIds = _prefs.getStringList(_compareKey) ?? <String>[];
    final offersJson = _prefs.getString(_offersKey);
    final offers = offersJson == null || offersJson.isEmpty
        ? List<Offer>.from(seedOffers)
        : Offer.decodeList(offersJson);

    _favoritesNotifier.value = favIds.toSet();
    _compareNotifier.value = compareIds.toSet();
    _offersNotifier.value = offers;
    _offersBadgeNotifier.value = offers.length;

    _rebuildFiltered();
    await paginate(reset: true);
  }

  Future<void> refresh({bool resetPage = false}) {
    return paginate(reset: resetPage);
  }

  Future<void> paginate({bool reset = false}) async {
    if (_isPaginating) {
      return;
    }
    if (reset) {
      _currentPage = 0;
      _visibleItemsNotifier.value = <Item>[];
    }
    if (isEnd(_currentPage, _filteredItems.length)) {
      _isLoadingNotifier.value = false;
      return;
    }
    _isPaginating = true;
    _isLoadingNotifier.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final nextItems = sliceForPage<Item>(_filteredItems, _currentPage);
    if (nextItems.isNotEmpty) {
      _currentPage += 1;
      _visibleItemsNotifier.value = <Item>[..._visibleItemsNotifier.value, ...nextItems];
      _itemsStreamController.add(_visibleItemsNotifier.value);
    }
    _isLoadingNotifier.value = false;
    _isPaginating = false;
  }

  void updateFilters(FilterOptions options) {
    _filters = options;
    _rebuildFiltered();
    paginate(reset: true);
  }

  void clearFilters() {
    updateFilters(FilterOptions.empty());
  }

  void setSortMode(SortMode mode) {
    if (_sortMode == mode) {
      return;
    }
    _sortMode = mode;
    _rebuildFiltered();
    paginate(reset: true);
  }

  List<Item> search(String query) {
    _searchQuery = query.trim();
    _rebuildFiltered();
    paginate(reset: true);
    return List<Item>.from(_filteredItems);
  }

  List<Item> _sorted(List<Item> items) {
    final sorted = List<Item>.from(items);
    switch (_sortMode) {
      case SortMode.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMode.priceLowToHigh:
        sorted.sort((a, b) => (a.price ?? double.infinity).compareTo(b.price ?? double.infinity));
        break;
      case SortMode.priceHighToLow:
        sorted.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
    }
    return sorted;
  }

  void _rebuildFiltered() {
    Iterable<Item> working = _allItems;
    if (_filters.hasFilters) {
      working = working.where(_filters.matches);
    }
    final list = _searchQuery.isEmpty
        ? List<Item>.from(working)
        : _rankedSearchResults(working);
    _filteredItems = _sorted(list);
    _currentPage = 0;
    _visibleItemsNotifier.value = <Item>[];
  }

  List<Item> _rankedSearchResults(Iterable<Item> source) {
    final query = _searchQuery.toLowerCase();
    final results = <_ScoredItem>[];
    for (final item in source) {
      int score = 0;
      final name = item.name.toLowerCase();
      final description = item.description.toLowerCase();
      if (name.contains(query)) {
        score += 6;
      }
      if (description.contains(query)) {
        score += 4;
      }
      if (item.category.toLowerCase().contains(query)) {
        score += 3;
      }
      if (item.condition.toLowerCase().contains(query)) {
        score += 2;
      }
      for (final entry in item.attrs.entries) {
        if (entry.key.toLowerCase().contains(query) || entry.value.toLowerCase().contains(query)) {
          score += 1;
          break;
        }
      }
      if (score > 0) {
        results.add(_ScoredItem(item, score));
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

  Future<void> toggleFavorite(String itemId) async {
    final favorites = <String>{..._favoritesNotifier.value};
    if (!favorites.add(itemId)) {
      favorites.remove(itemId);
    }
    _favoritesNotifier.value = favorites;
    _favoritesStreamController.add(favorites);
    await _prefs.setStringList(_favoritesKey, favorites.toList());
  }

  Future<void> toggleCompare(String itemId) async {
    final compare = <String>{..._compareNotifier.value};
    if (compare.contains(itemId)) {
      compare.remove(itemId);
    } else if (compare.length < 3) {
      compare.add(itemId);
    }
    _compareNotifier.value = compare;
    _compareStreamController.add(compare);
    await _prefs.setStringList(_compareKey, compare.toList());
  }

  Future<void> addItem(Item item) async {
    final index = _allItems.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      _allItems = <Item>[item, ..._allItems];
    } else {
      _allItems[index] = item;
    }
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    _rebuildFiltered();
    await paginate(reset: true);
  }

  Future<void> makeOffer(String itemId, double amount) async {
    final offer = Offer(
      id: 'of_${DateTime.now().millisecondsSinceEpoch}',
      itemId: itemId,
      buyer: 'Local buyer',
      amount: amount,
      createdAt: DateTime.now(),
    );
    _registerOffer(offer, incrementBadge: true);
    await _persistOffers();
  }

  void simulateIncomingOffers() {
    _scheduleOfferTick();
  }

  void _scheduleOfferTick() {
    _offerTimer?.cancel();
    final delay = Duration(seconds: 30 + _random.nextInt(61));
    _offerTimer = Timer(delay, _pushRandomOffer);
  }

  void _pushRandomOffer() {
    final candidates = _allItems.where((item) => item.allowOffers).toList();
    if (candidates.isEmpty) {
      _scheduleOfferTick();
      return;
    }
    final item = candidates[_random.nextInt(candidates.length)];
    final base = item.price ?? 20;
    final offset = base * (0.8 + _random.nextDouble() * 0.4);
    final offer = Offer(
      id: 'of_sim_${DateTime.now().millisecondsSinceEpoch}',
      itemId: item.id,
      buyer: 'Brew bidder',
      amount: double.parse(offset.toStringAsFixed(2)),
      createdAt: DateTime.now(),
    );
    _registerOffer(offer, incrementBadge: true);
    _persistOffers();
    _scheduleOfferTick();
  }

  void _registerOffer(Offer offer, {bool incrementBadge = false}) {
    final offers = <Offer>[..._offersNotifier.value, offer];
    _offersNotifier.value = offers;
    if (incrementBadge) {
      _offersBadgeNotifier.value = _offersBadgeNotifier.value + 1;
    }
  }

  Future<void> _persistOffers() {
    return _prefs.setString(_offersKey, Offer.encodeList(_offersNotifier.value));
  }

  List<Item> get allItems => List<Item>.unmodifiable(_allItems);

  List<Item> get favoritesItems =>
      _allItems.where((item) => _favoritesNotifier.value.contains(item.id)).toList();

  List<Item> get compareItems =>
      _allItems.where((item) => _compareNotifier.value.contains(item.id)).toList();

  Item? getById(String id) {
    try {
      return _allItems.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLocalData() async {
    await _prefs.remove(_itemsKey);
    await _prefs.remove(_favoritesKey);
    await _prefs.remove(_compareKey);
    await _prefs.remove(_offersKey);
    await seed();
    simulateIncomingOffers();
  }

  void dispose() {
    _offerTimer?.cancel();
    _visibleItemsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _favoritesNotifier.dispose();
    _compareNotifier.dispose();
    _offersNotifier.dispose();
    _offersBadgeNotifier.dispose();
    _itemsStreamController.close();
    _favoritesStreamController.close();
    _compareStreamController.close();
  }
}

class _ScoredItem {
  const _ScoredItem(this.item, this.score);

  final Item item;
  final int score;
}
