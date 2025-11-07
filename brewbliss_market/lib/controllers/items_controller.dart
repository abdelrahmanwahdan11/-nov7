import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/sample_data.dart';
import '../data/models/bundle.dart';
import '../data/models/collection.dart';
import '../data/models/item.dart';
import '../data/models/negotiation.dart';
import '../data/models/offer.dart';
import '../data/models/price_alert.dart';
import '../data/models/review.dart';
import '../data/models/saved_filter_adv.dart';
import '../data/models/saved_search.dart';
import '../data/models/undo_entry.dart';
import '../data/models/variant.dart';

const _itemsKey = 'items.json';
const _favoritesKey = 'favorites.ids';
const _compareKey = 'compare.ids';
const _offersKey = 'offers.json';
const _wishlistKey = 'wishlist.ids';
const _collectionsKey = 'collections.json';
const _savedSearchKey = 'saved_searches.json';
const _savedFiltersKey = 'advanced_filters.json';
const _priceAlertsKey = 'price_alerts.json';
const _reviewsKey = 'reviews.json';
const _priceHistoryKey = 'price_history.json';
const _bundlesKey = 'bundles.json';
const _undoKey = 'undo_stack.json';
const _negotiationsKey = 'negotiations.json';

class ItemsController extends ChangeNotifier {
  ItemsController._(this._prefs) {
    _visibleItemsNotifier = ValueNotifier<List<Item>>([]);
    _favoritesNotifier = ValueNotifier<Set<String>>({});
    _compareNotifier = ValueNotifier<Set<String>>({});
    _wishlistNotifier = ValueNotifier<Set<String>>({});
    _offersNotifier = ValueNotifier<List<Offer>>([]);
    _collectionsNotifier = ValueNotifier<List<Collection>>([]);
    _savedSearchesNotifier = ValueNotifier<List<SavedSearch>>([]);
    _savedFiltersNotifier = ValueNotifier<List<SavedFilterAdv>>([]);
    _priceAlertsNotifier = ValueNotifier<List<PriceAlert>>([]);
    _reviewsNotifier = ValueNotifier<Map<String, List<Review>>>({});
    _priceHistoryNotifier = ValueNotifier<Map<String, List<double>>>({});
    _bundlesNotifier = ValueNotifier<List<Bundle>>([]);
    _undoStackNotifier = ValueNotifier<List<UndoEntry>>([]);
    _itemsStreamController = StreamController<List<Item>>.broadcast();
    _favoritesStreamController = StreamController<Set<String>>.broadcast();
    _compareStreamController = StreamController<Set<String>>.broadcast();
    _wishlistStreamController = StreamController<Set<String>>.broadcast();
  }

  static Future<ItemsController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = ItemsController._(prefs);
    await controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  late final ValueNotifier<List<Item>> _visibleItemsNotifier;
  late final ValueNotifier<Set<String>> _favoritesNotifier;
  late final ValueNotifier<Set<String>> _compareNotifier;
  late final ValueNotifier<Set<String>> _wishlistNotifier;
  late final ValueNotifier<List<Offer>> _offersNotifier;
  late final ValueNotifier<List<Collection>> _collectionsNotifier;
  late final ValueNotifier<List<SavedSearch>> _savedSearchesNotifier;
  late final ValueNotifier<List<SavedFilterAdv>> _savedFiltersNotifier;
  late final ValueNotifier<List<PriceAlert>> _priceAlertsNotifier;
  late final ValueNotifier<Map<String, List<Review>>> _reviewsNotifier;
  late final ValueNotifier<Map<String, List<double>>> _priceHistoryNotifier;
  late final ValueNotifier<List<Bundle>> _bundlesNotifier;
  late final ValueNotifier<List<UndoEntry>> _undoStackNotifier;
  late final StreamController<List<Item>> _itemsStreamController;
  late final StreamController<Set<String>> _favoritesStreamController;
  late final StreamController<Set<String>> _compareStreamController;
  late final StreamController<Set<String>> _wishlistStreamController;

  List<Item> _allItems = [];
  List<Negotiation> _negotiations = [];
  bool _isFetching = false;
  int _currentPage = 0;
  static const _pageSize = 12;

  ValueListenable<List<Item>> get visibleItemsListenable => _visibleItemsNotifier;
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;
  ValueListenable<Set<String>> get compareListenable => _compareNotifier;
  ValueListenable<Set<String>> get wishlistListenable => _wishlistNotifier;
  ValueListenable<List<Offer>> get offersListenable => _offersNotifier;
  ValueListenable<List<Collection>> get collectionsListenable => _collectionsNotifier;
  ValueListenable<List<SavedSearch>> get savedSearchesListenable =>
      _savedSearchesNotifier;
  ValueListenable<List<SavedFilterAdv>> get savedFiltersListenable =>
      _savedFiltersNotifier;
  ValueListenable<List<PriceAlert>> get priceAlertsListenable =>
      _priceAlertsNotifier;
  ValueListenable<Map<String, List<Review>>> get reviewsListenable =>
      _reviewsNotifier;
  ValueListenable<Map<String, List<double>>> get priceHistoryListenable =>
      _priceHistoryNotifier;
  ValueListenable<List<Bundle>> get bundlesListenable => _bundlesNotifier;
  ValueListenable<List<UndoEntry>> get undoStackListenable => _undoStackNotifier;

  Stream<List<Item>> get itemsStream => _itemsStreamController.stream;
  Stream<Set<String>> get favoritesStream => _favoritesStreamController.stream;
  Stream<Set<String>> get compareStream => _compareStreamController.stream;
  Stream<Set<String>> get wishlistStream => _wishlistStreamController.stream;

  List<Item> get allItems => _allItems;
  List<Negotiation> get negotiations => _negotiations;

  Future<void> _load() async {
    _allItems = await _loadItems();
    _favoritesNotifier.value = {...(_prefs.getStringList(_favoritesKey) ?? [])};
    _compareNotifier.value = {...(_prefs.getStringList(_compareKey) ?? [])};
    _wishlistNotifier.value = {...(_prefs.getStringList(_wishlistKey) ?? [])};
    _offersNotifier.value = await _loadOffers();
    _collectionsNotifier.value = await _loadCollections();
    _savedSearchesNotifier.value = await _loadSavedSearches();
    _savedFiltersNotifier.value = await _loadSavedFilters();
    _priceAlertsNotifier.value = await _loadPriceAlerts();
    _reviewsNotifier.value = await _loadReviews();
    _priceHistoryNotifier.value = await _loadPriceHistory();
    _bundlesNotifier.value = await _loadBundles();
    _undoStackNotifier.value = await _loadUndoStack();
    _negotiations = await _loadNegotiations();
    await refresh(resetPage: true);
  }

  Future<List<Item>> _loadItems() async {
    final itemsJson = _prefs.getString(_itemsKey);
    if (itemsJson != null && itemsJson.isNotEmpty) {
      return Item.decodeList(itemsJson);
    }
    await _prefs.setString(_itemsKey, Item.encodeList(seedItems));
    return [...seedItems];
  }

  Future<List<Offer>> _loadOffers() async {
    final offersJson = _prefs.getString(_offersKey);
    if (offersJson == null || offersJson.isEmpty) {
      await _prefs.setString(_offersKey, Offer.encodeList(seedOffers));
      return [...seedOffers];
    }
    return Offer.decodeList(offersJson);
  }

  Future<List<Collection>> _loadCollections() async {
    final json = _prefs.getString(_collectionsKey);
    if (json == null || json.isEmpty) {
      await _prefs.setString(
        _collectionsKey,
        Collection.encodeList(seedCollections),
      );
      return [...seedCollections];
    }
    return Collection.decodeList(json);
  }

  Future<List<SavedSearch>> _loadSavedSearches() async {
    final json = _prefs.getString(_savedSearchKey);
    if (json == null || json.isEmpty) return [];
    return SavedSearch.decodeList(json);
  }

  Future<List<SavedFilterAdv>> _loadSavedFilters() async {
    final json = _prefs.getString(_savedFiltersKey);
    if (json == null || json.isEmpty) return [];
    return SavedFilterAdv.decodeList(json);
  }

  Future<List<PriceAlert>> _loadPriceAlerts() async {
    final json = _prefs.getString(_priceAlertsKey);
    if (json == null || json.isEmpty) return [];
    return PriceAlert.decodeList(json);
  }

  Future<Map<String, List<Review>>> _loadReviews() async {
    final json = _prefs.getString(_reviewsKey);
    if (json == null || json.isEmpty) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));
  }

  Future<Map<String, List<double>>> _loadPriceHistory() async {
    final json = _prefs.getString(_priceHistoryKey);
    if (json == null || json.isEmpty) return {};
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
        ));
  }

  Future<List<Bundle>> _loadBundles() async {
    final json = _prefs.getString(_bundlesKey);
    if (json == null || json.isEmpty) {
      await _prefs.setString(
        _bundlesKey,
        Bundle.encodeList(seedBundles),
      );
      return [...seedBundles];
    }
    return Bundle.decodeList(json);
  }

  Future<List<UndoEntry>> _loadUndoStack() async {
    final json = _prefs.getString(_undoKey);
    if (json == null || json.isEmpty) return [];
    return UndoEntry.decodeList(json);
  }

  Future<List<Negotiation>> _loadNegotiations() async {
    final json = _prefs.getString(_negotiationsKey);
    if (json == null || json.isEmpty) return [];
    return Negotiation.decodeList(json);
  }

  Future<void> refresh({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 0;
      _visibleItemsNotifier.value = [];
    }
    _itemsStreamController.add(_visibleItemsNotifier.value);
    await fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (_isFetching) return;
    _isFetching = true;
    final start = _currentPage * _pageSize;
    if (start >= _allItems.length) {
      _isFetching = false;
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final end = ((_currentPage + 1) * _pageSize).clamp(0, _allItems.length) as int;
    final next = _allItems.sublist(start, end);
    _currentPage++;
    _visibleItemsNotifier.value = [..._visibleItemsNotifier.value, ...next];
    _itemsStreamController.add(_visibleItemsNotifier.value);
    _isFetching = false;
  }

  Future<void> setItems(List<Item> items) async {
    _allItems = items;
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    await refresh(resetPage: true);
  }

  Future<void> addOrUpdateItem(Item item, {bool pushUndo = true}) async {
    final index = _allItems.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      _allItems = [item, ..._allItems];
    } else {
      _allItems[index] = item;
    }
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    if (pushUndo) {
      _pushUndo(
        UndoEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          action: 'item_updated',
          payload: item.toJson(),
          timestamp: DateTime.now(),
        ),
      );
    }
    await refresh(resetPage: true);
  }

  Future<void> seedIfEmpty() async {
    if (_allItems.isEmpty) {
      await setItems(seedItems);
    }
  }

  Future<void> toggleFavorite(String itemId) async {
    final favorites = {..._favoritesNotifier.value};
    if (!favorites.add(itemId)) {
      favorites.remove(itemId);
    }
    _favoritesNotifier.value = favorites;
    _favoritesStreamController.add(favorites);
    await _prefs.setStringList(_favoritesKey, favorites.toList());
  }

  Future<void> toggleCompare(String itemId) async {
    final compare = {..._compareNotifier.value};
    if (compare.contains(itemId)) {
      compare.remove(itemId);
    } else if (compare.length < 3) {
      compare.add(itemId);
    }
    _compareNotifier.value = compare;
    _compareStreamController.add(compare);
    await _prefs.setStringList(_compareKey, compare.toList());
  }

  Future<void> toggleWishlist(String itemId) async {
    final wishlist = {..._wishlistNotifier.value};
    if (!wishlist.add(itemId)) {
      wishlist.remove(itemId);
    }
    _wishlistNotifier.value = wishlist;
    _wishlistStreamController.add(wishlist);
    await _prefs.setStringList(_wishlistKey, wishlist.toList());
  }

  Future<void> addCollection(Collection collection) async {
    final collections = [..._collectionsNotifier.value, collection];
    _collectionsNotifier.value = collections;
    await _prefs.setString(_collectionsKey, Collection.encodeList(collections));
  }

  Future<void> updateCollection(Collection collection) async {
    final collections = [..._collectionsNotifier.value];
    final index = collections.indexWhere((element) => element.id == collection.id);
    if (index != -1) {
      collections[index] = collection;
      _collectionsNotifier.value = collections;
      await _prefs.setString(_collectionsKey, Collection.encodeList(collections));
    }
  }

  Future<void> removeCollection(String id) async {
    final collections = [..._collectionsNotifier.value]..removeWhere((e) => e.id == id);
    _collectionsNotifier.value = collections;
    await _prefs.setString(_collectionsKey, Collection.encodeList(collections));
  }

  Future<void> addSavedSearch(SavedSearch savedSearch) async {
    final searches = [..._savedSearchesNotifier.value, savedSearch];
    _savedSearchesNotifier.value = searches;
    await _prefs.setString(_savedSearchKey, SavedSearch.encodeList(searches));
  }

  Future<void> removeSavedSearch(String id) async {
    final searches = [..._savedSearchesNotifier.value]
      ..removeWhere((element) => element.id == id);
    _savedSearchesNotifier.value = searches;
    await _prefs.setString(_savedSearchKey, SavedSearch.encodeList(searches));
  }

  Future<void> addSavedFilter(SavedFilterAdv filter) async {
    final filters = [..._savedFiltersNotifier.value, filter];
    _savedFiltersNotifier.value = filters;
    await _prefs.setString(_savedFiltersKey, SavedFilterAdv.encodeList(filters));
  }

  Future<void> removeSavedFilter(String id) async {
    final filters = [..._savedFiltersNotifier.value]
      ..removeWhere((element) => element.id == id);
    _savedFiltersNotifier.value = filters;
    await _prefs.setString(_savedFiltersKey, SavedFilterAdv.encodeList(filters));
  }

  Future<void> addPriceAlert(PriceAlert alert) async {
    final alerts = [..._priceAlertsNotifier.value, alert];
    _priceAlertsNotifier.value = alerts;
    await _prefs.setString(_priceAlertsKey, PriceAlert.encodeList(alerts));
  }

  Future<void> updatePriceAlert(PriceAlert alert) async {
    final alerts = [..._priceAlertsNotifier.value];
    final index = alerts.indexWhere((element) => element.id == alert.id);
    if (index != -1) {
      alerts[index] = alert;
      _priceAlertsNotifier.value = alerts;
      await _prefs.setString(_priceAlertsKey, PriceAlert.encodeList(alerts));
    }
  }

  Future<void> removePriceAlert(String id) async {
    final alerts = [..._priceAlertsNotifier.value]
      ..removeWhere((element) => element.id == id);
    _priceAlertsNotifier.value = alerts;
    await _prefs.setString(_priceAlertsKey, PriceAlert.encodeList(alerts));
  }

  Future<void> addReview(String itemId, Review review) async {
    final map = {..._reviewsNotifier.value};
    final list = [...(map[itemId] ?? const [])];
    list.add(review);
    map[itemId] = list;
    _reviewsNotifier.value = map;
    await _persistReviews(map);
    final itemIndex = _allItems.indexWhere((element) => element.id == itemId);
    if (itemIndex != -1) {
      final item = _allItems[itemIndex];
      final newCount = item.ratingCount + 1;
      final newAvg = ((item.ratingAvg * item.ratingCount) + review.stars) / newCount;
      _allItems[itemIndex] = item.copyWith(
        ratingAvg: double.parse(newAvg.toStringAsFixed(2)),
        ratingCount: newCount,
      );
      await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
      notifyListeners();
    }
  }

  Future<void> _persistReviews(Map<String, List<Review>> map) async {
    final encoded = jsonEncode(
      map.map((key, value) => MapEntry(key, value.map((e) => e.toJson()).toList())),
    );
    await _prefs.setString(_reviewsKey, encoded);
  }

  Future<void> appendPricePoint(String itemId, double value) async {
    final map = {..._priceHistoryNotifier.value};
    final history = [...(map[itemId] ?? const [])];
    history.add(value);
    map[itemId] = history;
    _priceHistoryNotifier.value = map;
    await _prefs.setString(_priceHistoryKey, jsonEncode(map));
  }

  Future<void> addBundle(Bundle bundle) async {
    final bundles = [..._bundlesNotifier.value, bundle];
    _bundlesNotifier.value = bundles;
    await _prefs.setString(_bundlesKey, Bundle.encodeList(bundles));
  }

  Future<void> updateBundle(Bundle bundle) async {
    final bundles = [..._bundlesNotifier.value];
    final index = bundles.indexWhere((element) => element.id == bundle.id);
    if (index != -1) {
      bundles[index] = bundle;
      _bundlesNotifier.value = bundles;
      await _prefs.setString(_bundlesKey, Bundle.encodeList(bundles));
    }
  }

  Future<void> removeBundle(String id) async {
    final bundles = [..._bundlesNotifier.value]..removeWhere((e) => e.id == id);
    _bundlesNotifier.value = bundles;
    await _prefs.setString(_bundlesKey, Bundle.encodeList(bundles));
  }

  Future<void> recordOffer(Offer offer) async {
    final offers = [..._offersNotifier.value, offer];
    _offersNotifier.value = offers;
    await _prefs.setString(_offersKey, Offer.encodeList(offers));
  }

  Future<void> recordNegotiation(Negotiation negotiation) async {
    final list = [..._negotiations]
      ..removeWhere((element) => element.id == negotiation.id);
    list.add(negotiation);
    _negotiations = list;
    await _prefs.setString(_negotiationsKey, Negotiation.encodeList(list));
  }

  List<Item> get favoritesItems =>
      _allItems.where((item) => _favoritesNotifier.value.contains(item.id)).toList();

  List<Item> get compareItems =>
      _allItems.where((item) => _compareNotifier.value.contains(item.id)).toList();

  List<Item> get wishlistItems =>
      _allItems.where((item) => _wishlistNotifier.value.contains(item.id)).toList();

  Item? getById(String id) {
    try {
      return _allItems.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Item> search(String query, {Map<String, dynamic>? filters}) {
    final lower = query.toLowerCase();
    final filtered = _allItems.where((item) {
      if (filters != null) {
        if (filters['category'] != null && filters['category'] != item.category) {
          return false;
        }
        if (filters['condition'] != null && filters['condition'] != item.condition) {
          return false;
        }
        if (filters['allowOffers'] != null && filters['allowOffers'] != item.allowOffers) {
          return false;
        }
        final minPrice = filters['minPrice'] as double?;
        final maxPrice = filters['maxPrice'] as double?;
        if (minPrice != null && (item.price ?? 0) < minPrice) return false;
        if (maxPrice != null && (item.price ?? double.infinity) > maxPrice) return false;
      }
      final score = _searchScore(item, lower);
      return score > 0;
    }).toList();
    filtered.sort((a, b) => _searchScore(b, lower).compareTo(_searchScore(a, lower)));
    return filtered;
  }

  int _searchScore(Item item, String q) {
    var score = 0;
    if (item.name.toLowerCase().contains(q)) score += 6;
    if (item.description.toLowerCase().contains(q)) score += 3;
    if (item.category.toLowerCase().contains(q)) score += 2;
    if (item.condition.toLowerCase().contains(q)) score += 1;
    if (item.tags.any((tag) => tag.toLowerCase().contains(q))) score += 4;
    if (item.attrs.values.any((value) => value.toLowerCase().contains(q))) score += 2;
    return score;
  }

  List<Item> similarItems(String itemId, {int limit = 10}) {
    final item = getById(itemId);
    if (item == null) return [];
    final scored = _allItems.where((element) => element.id != item.id).map((other) {
      var score = 0.0;
      if (other.category == item.category) score += 2;
      score += _intersectionScore(item.tags, other.tags);
      score += _mapIntersectionScore(item.attrs, other.attrs);
      if (other.condition == item.condition) score += 0.5;
      return MapEntry(other, score);
    }).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  double _intersectionScore(List<String> a, List<String> b) {
    final setA = a.map((e) => e.toLowerCase()).toSet();
    final setB = b.map((e) => e.toLowerCase()).toSet();
    return setA.intersection(setB).length.toDouble();
  }

  double _mapIntersectionScore(Map<String, String> a, Map<String, String> b) {
    var score = 0.0;
    for (final entry in a.entries) {
      if (b[entry.key] == entry.value) score += 0.5;
    }
    return score;
  }

  Future<void> setVariantSelection(String itemId, String? variantId) async {
    final index = _allItems.indexWhere((element) => element.id == itemId);
    if (index != -1) {
      final item = _allItems[index];
      _allItems[index] = item.copyWith(variantSelectedId: variantId);
      await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
      notifyListeners();
    }
  }

  Future<void> importItemsFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;
    final List<Item> imported = decoded
        .whereType<Map<String, dynamic>>()
        .map(Item.fromJson)
        .toList();
    _allItems = [...imported, ..._allItems];
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    await refresh(resetPage: true);
  }

  List<Item> applyAdvancedFilter(String expression) {
    return _allItems.where((item) => _evaluateExpression(expression, item)).toList();
  }

  bool _evaluateExpression(String expression, Item item) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return true;
    final orParts = _splitTopLevel(trimmed, 'OR');
    if (orParts.length > 1) {
      return orParts.any((part) => _evaluateExpression(part, item));
    }
    final andParts = _splitTopLevel(trimmed, 'AND');
    if (andParts.length > 1) {
      return andParts.every((part) => _evaluateExpression(part, item));
    }
    if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      return _evaluateExpression(trimmed.substring(1, trimmed.length - 1), item);
    }
    return _evaluateCondition(trimmed, item);
  }

  List<String> _splitTopLevel(String expression, String keyword) {
    final result = <String>[];
    var depth = 0;
    var buffer = StringBuffer();
    final upperKeyword = ' $keyword ';
    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (char == '(') depth++;
      if (char == ')') depth--;
      buffer.write(char);
      final current = buffer.toString();
      if (depth == 0 && current.endsWith(upperKeyword)) {
        result.add(current.substring(0, current.length - upperKeyword.length));
        buffer = StringBuffer();
      }
    }
    final tail = buffer.toString().trim();
    if (tail.isNotEmpty) result.add(tail);
    return result.map((e) => e.trim()).where((element) => element.isNotEmpty).toList();
  }

  bool _evaluateCondition(String condition, Item item) {
    final eqMatch = RegExp(r"(\w+)\s*==\s*\"([^\"]+)\"").firstMatch(condition);
    if (eqMatch != null) {
      final field = eqMatch.group(1)!;
      final value = eqMatch.group(2)!.toLowerCase();
      switch (field) {
        case 'category':
          return item.category.toLowerCase() == value;
        case 'condition':
          return item.condition.toLowerCase() == value;
        case 'allowOffers':
          return (item.allowOffers ? 'true' : 'false') == value;
        case 'bundleId':
          return (item.bundleId ?? '').toLowerCase() == value;
      }
    }
    final tagMatch = RegExp(r"tags~\"([^\"]+)\"").firstMatch(condition);
    if (tagMatch != null) {
      final value = tagMatch.group(1)!.toLowerCase();
      return item.tags.any((tag) => tag.toLowerCase().contains(value)) ||
          item.tagsSuggested.any((tag) => tag.toLowerCase().contains(value));
    }
    final lessMatch = RegExp(r"(price)\s*<\s*(\d+(?:\.\d+)?)").firstMatch(condition);
    if (lessMatch != null) {
      final value = double.parse(lessMatch.group(2)!);
      return (item.price ?? double.infinity) < value;
    }
    final greaterMatch = RegExp(r"(price)\s*>\s*(\d+(?:\.\d+)?)").firstMatch(condition);
    if (greaterMatch != null) {
      final value = double.parse(greaterMatch.group(2)!);
      return (item.price ?? 0) > value;
    }
    final containsMatch = RegExp(r"(name|description)~\"([^\"]+)\"")
        .firstMatch(condition);
    if (containsMatch != null) {
      final field = containsMatch.group(1)!;
      final value = containsMatch.group(2)!.toLowerCase();
      final target = field == 'name' ? item.name : item.description;
      return target.toLowerCase().contains(value);
    }
    return false;
  }

  double bundleTotal(String bundleId) {
    final bundle = _bundlesNotifier.value.firstWhere(
      (element) => element.id == bundleId,
      orElse: () =>
          Bundle(id: 'missing', name: 'Missing', itemIds: const [], bundlePrice: 0),
    );
    if (bundle.bundlePrice > 0) return bundle.bundlePrice;
    return bundle.itemIds
        .map((id) => getById(id)?.displayPrice ?? 0)
        .fold<double>(0, (previousValue, element) => previousValue + element);
  }

  void _pushUndo(UndoEntry entry) {
    final list = [..._undoStackNotifier.value, entry];
    final trimmed = list.length > 20 ? list.sublist(list.length - 20) : list;
    _undoStackNotifier.value = trimmed;
    _prefs.setString(_undoKey, UndoEntry.encodeList(trimmed));
  }

  Future<void> applyUndo() async {
    final list = [..._undoStackNotifier.value];
    if (list.isEmpty) return;
    final last = list.removeLast();
    _undoStackNotifier.value = list;
    await _prefs.setString(_undoKey, UndoEntry.encodeList(list));
    if (last.action == 'item_updated') {
      final restored = Item.fromJson(last.payload);
      await addOrUpdateItem(restored, pushUndo: false);
    }
  }

  Future<void> clearLocalData() async {
    await _prefs.remove(_itemsKey);
    await _prefs.remove(_favoritesKey);
    await _prefs.remove(_compareKey);
    await _prefs.remove(_offersKey);
    await _prefs.remove(_wishlistKey);
    await _prefs.remove(_collectionsKey);
    await _prefs.remove(_savedSearchKey);
    await _prefs.remove(_savedFiltersKey);
    await _prefs.remove(_priceAlertsKey);
    await _prefs.remove(_reviewsKey);
    await _prefs.remove(_priceHistoryKey);
    await _prefs.remove(_bundlesKey);
    await _prefs.remove(_undoKey);
    await _prefs.remove(_negotiationsKey);
    await _load();
    notifyListeners();
  }

  Map<String, double> recommenderScore({Set<String>? favorites, Set<String>? compares}) {
    final favSet = favorites ?? _favoritesNotifier.value;
    final compareSet = compares ?? _compareNotifier.value;
    final wishlist = _wishlistNotifier.value;
    final random = Random();
    final scores = <String, double>{};
    for (final item in _allItems) {
      var score = 0.0;
      if (favSet.contains(item.id)) score += 3;
      if (compareSet.contains(item.id)) score += 2;
      if (wishlist.contains(item.id)) score += 1.5;
      score += (item.ratingAvg * (item.ratingCount / 5.0));
      score += random.nextDouble() * 0.5;
      scores[item.id] = score;
    }
    return scores;
  }

  List<Item> recommenderV2({int limit = 10}) {
    final scores = recommenderScore();
    final entries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => getById(e.key)).whereType<Item>().take(limit).toList();
  }

  @override
  void dispose() {
    _visibleItemsNotifier.dispose();
    _favoritesNotifier.dispose();
    _compareNotifier.dispose();
    _wishlistNotifier.dispose();
    _offersNotifier.dispose();
    _collectionsNotifier.dispose();
    _savedSearchesNotifier.dispose();
    _savedFiltersNotifier.dispose();
    _priceAlertsNotifier.dispose();
    _reviewsNotifier.dispose();
    _priceHistoryNotifier.dispose();
    _bundlesNotifier.dispose();
    _undoStackNotifier.dispose();
    _itemsStreamController.close();
    _favoritesStreamController.close();
    _compareStreamController.close();
    _wishlistStreamController.close();
    super.dispose();
  }
}
