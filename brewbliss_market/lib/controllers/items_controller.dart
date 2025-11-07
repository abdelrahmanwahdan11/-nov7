import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/sample_data.dart';
import '../data/models/collection.dart';
import '../data/models/item.dart';
import '../data/models/offer.dart';
import '../data/models/review.dart';

const _itemsKey = 'items.json';
const _favoritesKey = 'favorites.ids';
const _compareKey = 'compare.ids';
const _offersKey = 'offers.json';
const _wishlistKey = 'wishlist.ids';
const _collectionsKey = 'collections.json';
const _reviewsKey = 'reviews.json';
const _priceHistoryKey = 'price_history.json';

class ItemsController {
  ItemsController._(this._prefs) {
    _visibleItemsNotifier = ValueNotifier<List<Item>>([]);
    _favoritesNotifier = ValueNotifier<Set<String>>({});
    _compareNotifier = ValueNotifier<Set<String>>({});
    _offersNotifier = ValueNotifier<List<Offer>>([]);
    _wishlistNotifier = ValueNotifier<Set<String>>({});
    _collectionsNotifier = ValueNotifier<List<Collection>>([]);
    _reviewsNotifier = ValueNotifier<Map<String, List<Review>>>({});
    _itemsStreamController = StreamController<List<Item>>.broadcast();
    _favoritesStreamController = StreamController<Set<String>>.broadcast();
    _compareStreamController = StreamController<Set<String>>.broadcast();
    _wishlistStreamController = StreamController<Set<String>>.broadcast();
    _collectionsStreamController = StreamController<List<Collection>>.broadcast();
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
  late final ValueNotifier<List<Offer>> _offersNotifier;
  late final ValueNotifier<Set<String>> _wishlistNotifier;
  late final ValueNotifier<List<Collection>> _collectionsNotifier;
  late final ValueNotifier<Map<String, List<Review>>> _reviewsNotifier;
  late final StreamController<List<Item>> _itemsStreamController;
  late final StreamController<Set<String>> _favoritesStreamController;
  late final StreamController<Set<String>> _compareStreamController;
  late final StreamController<Set<String>> _wishlistStreamController;
  late final StreamController<List<Collection>> _collectionsStreamController;
  Timer? _offerTimer;
  final Random _random = Random();

  List<Item> _allItems = [];
  bool _isFetching = false;
  int _currentPage = 0;
  static const _pageSize = 12;
  Map<String, List<double>> _priceHistory = {};

  ValueListenable<List<Item>> get visibleItemsListenable => _visibleItemsNotifier;
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;
  ValueListenable<Set<String>> get compareListenable => _compareNotifier;
  ValueListenable<List<Offer>> get offersListenable => _offersNotifier;
  ValueListenable<Set<String>> get wishlistListenable => _wishlistNotifier;
  ValueListenable<List<Collection>> get collectionsListenable => _collectionsNotifier;
  ValueListenable<Map<String, List<Review>>> get reviewsListenable => _reviewsNotifier;

  Stream<List<Item>> get itemsStream => _itemsStreamController.stream;
  Stream<Set<String>> get favoritesStream => _favoritesStreamController.stream;
  Stream<Set<String>> get compareStream => _compareStreamController.stream;
  Stream<Set<String>> get wishlistStream => _wishlistStreamController.stream;
  Stream<List<Collection>> get collectionsStream => _collectionsStreamController.stream;

  List<Collection> get collections => List<Collection>.unmodifiable(_collectionsNotifier.value);

  Future<void> _load() async {
    final itemsJson = _prefs.getString(_itemsKey);
    if (itemsJson != null && itemsJson.isNotEmpty) {
      _allItems = Item.decodeList(itemsJson);
    } else {
      _allItems = seedItems;
      await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    }

    final favIds = _prefs.getStringList(_favoritesKey) ?? [];
    final compareIds = _prefs.getStringList(_compareKey) ?? [];
    final wishlistIds = _prefs.getStringList(_wishlistKey) ?? [];
    final offersJson = _prefs.getString(_offersKey);
    final offers = offersJson == null || offersJson.isEmpty
        ? seedOffers
        : Offer.decodeList(offersJson);
    final collectionsJson = _prefs.getString(_collectionsKey);
    final collections = collectionsJson == null || collectionsJson.isEmpty
        ? <Collection>[]
        : Collection.decodeList(collectionsJson);

    final reviewsJson = _prefs.getString(_reviewsKey);
    final Map<String, List<Review>> reviews = {};
    if (reviewsJson != null && reviewsJson.isNotEmpty) {
      final decoded = jsonDecode(reviewsJson) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final list = (entry.value as List<dynamic>)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList();
        reviews[entry.key] = list;
      }
    }

    final priceHistoryJson = _prefs.getString(_priceHistoryKey);
    if (priceHistoryJson != null && priceHistoryJson.isNotEmpty) {
      final decoded = jsonDecode(priceHistoryJson) as Map<String, dynamic>;
      _priceHistory = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
        ),
      );
    } else {
      _priceHistory = {};
    }

    _favoritesNotifier.value = {...favIds};
    _compareNotifier.value = {...compareIds};
    _wishlistNotifier.value = {...wishlistIds};
    _collectionsNotifier.value = [...collections];
    _reviewsNotifier.value = reviews;
    _offersNotifier.value = [...offers];

    _favoritesStreamController.add(_favoritesNotifier.value);
    _compareStreamController.add(_compareNotifier.value);
    _wishlistStreamController.add(_wishlistNotifier.value);
    _collectionsStreamController.add(_collectionsNotifier.value);

    _allItems = _allItems.map((item) {
      final history = _priceHistory[item.id] ??
          (item.priceHistory.isNotEmpty
              ? item.priceHistory
              : item.price != null
                  ? <double>[item.price!]
                  : <double>[]);
      _priceHistory[item.id] = history;
      final itemReviews = reviews[item.id] ?? const <Review>[];
      final ratingCount = itemReviews.length;
      final ratingAvg = ratingCount == 0
          ? (item.ratingAvg == 0 ? 0.0 : item.ratingAvg)
          : itemReviews.fold<double>(0, (acc, r) => acc + r.stars) / ratingCount;
      return item.copyWith(
        priceHistory: history,
        ratingCount: ratingCount,
        ratingAvg: double.parse(ratingAvg.toStringAsFixed(2)),
        tags: item.tags.isEmpty ? _deriveTags(item) : item.tags,
      );
    }).toList();

    await refresh(resetPage: true);
    _scheduleOfferSimulation();
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final end = ((_currentPage + 1) * _pageSize).clamp(0, _allItems.length) as int;
    final next = _allItems.sublist(start, end);
    _currentPage++;
    _visibleItemsNotifier.value = [..._visibleItemsNotifier.value, ...next];
    _itemsStreamController.add(_visibleItemsNotifier.value);
    _isFetching = false;
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

  Future<void> addOrUpdateItem(Item item) async {
    final normalizedTags = item.tags.isEmpty ? _deriveTags(item) : item.tags;
    final normalizedHistory = item.priceHistory.isNotEmpty
        ? item.priceHistory
        : item.price != null
            ? <double>[item.price!]
            : _priceHistory[item.id] ?? <double>[];
    final normalizedItem = item.copyWith(
      tags: normalizedTags,
      priceHistory: normalizedHistory,
    );
    _priceHistory[normalizedItem.id] = [...normalizedHistory];
    final index = _allItems.indexWhere((e) => e.id == normalizedItem.id);
    if (index == -1) {
      _allItems = [normalizedItem, ..._allItems];
    } else {
      _allItems[index] = normalizedItem;
    }
    await _persistItems();
    await _persistPriceHistory();
    await refresh(resetPage: true);
    _scheduleOfferSimulation();
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

  bool isWishlisted(String itemId) => _wishlistNotifier.value.contains(itemId);

  Future<Collection> createCollection(String name) async {
    final collection = Collection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      itemIds: const <String>[],
      createdAt: DateTime.now(),
    );
    final collections = [..._collectionsNotifier.value, collection];
    _collectionsNotifier.value = collections;
    _collectionsStreamController.add(collections);
    await _persistCollections();
    return collection;
  }

  Future<void> renameCollection(String id, String name) async {
    final collections = _collectionsNotifier.value.map((collection) {
      if (collection.id == id) {
        return collection.copyWith(name: name);
      }
      return collection;
    }).toList();
    _collectionsNotifier.value = collections;
    _collectionsStreamController.add(collections);
    await _persistCollections();
  }

  Future<void> deleteCollection(String id) async {
    final collections = _collectionsNotifier.value.where((c) => c.id != id).toList();
    _collectionsNotifier.value = collections;
    _collectionsStreamController.add(collections);
    await _persistCollections();
  }

  Future<void> toggleCollectionItem(String collectionId, String itemId) async {
    final collections = _collectionsNotifier.value.map((collection) {
      if (collection.id == collectionId) {
        final items = [...collection.itemIds];
        if (!items.contains(itemId)) {
          items.add(itemId);
        } else {
          items.remove(itemId);
        }
        return collection.copyWith(itemIds: items);
      }
      return collection;
    }).toList();
    _collectionsNotifier.value = collections;
    _collectionsStreamController.add(collections);
    await _persistCollections();
  }

  List<Item> itemsForCollection(String id) {
    try {
      final collection =
          _collectionsNotifier.value.firstWhere((element) => element.id == id);
      return _allItems.where((item) => collection.itemIds.contains(item.id)).toList();
    } catch (_) {
      return const <Item>[];
    }
  }

  Future<void> addReview(String itemId, int stars, String text) async {
    final map = {..._reviewsNotifier.value};
    final reviews = [...(map[itemId] ?? const <Review>[])];
    reviews.add(
      Review(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemId: itemId,
        stars: stars.clamp(1, 5),
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    map[itemId] = reviews;
    _reviewsNotifier.value = map;
    await _persistReviews();
    await _updateRatingForItem(itemId, reviews);
  }

  List<Review> reviewsFor(String itemId) => _reviewsNotifier.value[itemId] ?? const <Review>[];

  Future<void> appendPricePoint(String itemId, double value) async {
    final history = [...(_priceHistory[itemId] ?? const <double>[])];
    history.add(double.parse(value.toStringAsFixed(2)));
    _priceHistory[itemId] = history;
    await _persistPriceHistory();
    final index = _allItems.indexWhere((element) => element.id == itemId);
    if (index != -1) {
      final updated = _allItems[index].copyWith(priceHistory: history);
      _allItems[index] = updated;
      await _persistItems();
      _refreshVisibleItem(updated);
    }
  }

  List<double> priceHistoryFor(String itemId) => _priceHistory[itemId] ?? const <double>[];

  List<Item> similarItems(String itemId) {
    final base = getById(itemId);
    if (base == null) {
      return const <Item>[];
    }
    final List<MapEntry<Item, double>> scored = [];
    for (final item in _allItems) {
      if (item.id == itemId) continue;
      double score = 0;
      if (item.category == base.category) {
        score += 2;
      }
      final tagOverlap = item.tags.toSet().intersection(base.tags.toSet()).length;
      score += tagOverlap;
      final sharedAttrs = item.attrs.entries.where((entry) {
        return base.attrs[entry.key]?.toLowerCase() == entry.value.toLowerCase();
      }).length;
      score += sharedAttrs * 0.5;
      if (item.condition == base.condition) {
        score += 0.5;
      }
      if (score > 0) {
        scored.add(MapEntry(item, score));
      }
    }
    scored.sort((a, b) {
      final diff = b.value.compareTo(a.value);
      if (diff != 0) return diff;
      return b.key.createdAt.compareTo(a.key.createdAt);
    });
    return scored.map((entry) => entry.key).take(10).toList();
  }

  Future<int> importItemsFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Expected a JSON array of items');
    }
    var imported = 0;
    final List<Item> incoming = [];
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }
      final map = Map<String, dynamic>.from(entry);
      map['createdAt'] ??= DateTime.now().toIso8601String();
      map['attrs'] = (map['attrs'] as Map?)
              ?.map((key, value) => MapEntry('$key', '$value')) ??
          <String, String>{};
      map['images'] = (map['images'] as List?)?.map((e) => '$e').toList() ??
          <String>[];
      map['allowOffers'] = map['allowOffers'] ?? false;
      if (!map.containsKey('id') ||
          !map.containsKey('name') ||
          !map.containsKey('description') ||
          !map.containsKey('category') ||
          !map.containsKey('condition') ||
          !map.containsKey('attrs')) {
        continue;
      }
      final item = Item.fromJson(map);
      final tags = (map['tags'] as List<dynamic>?)?.cast<String>() ??
          _deriveTags(item);
      final history = (map['priceHistory'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          (item.price != null ? <double>[item.price!] : <double>[]);
      incoming.add(item.copyWith(tags: tags, priceHistory: history));
      imported++;
    }
    if (incoming.isEmpty) {
      return 0;
    }
    for (final item in incoming) {
      final index = _allItems.indexWhere((element) => element.id == item.id);
      _priceHistory[item.id] = [...item.priceHistory];
      if (index == -1) {
        _allItems = [item, ..._allItems];
      } else {
        _allItems[index] = item;
      }
    }
    await _persistItems();
    await _persistPriceHistory();
    await refresh(resetPage: true);
    return imported;
  }

  Future<void> recordOffer(Offer offer) async {
    final offers = [..._offersNotifier.value, offer];
    _offersNotifier.value = offers;
    await _prefs.setString(_offersKey, Offer.encodeList(offers));
  }

  Future<void> makeOffer(String itemId, double amount, {String buyer = 'Guest'}) async {
    final offer = Offer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: itemId,
      buyer: buyer,
      amount: amount,
      createdAt: DateTime.now(),
    );
    await recordOffer(offer);
  }

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

  List<Item> search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return _allItems;
    }
    final Map<String, double> scores = {};
    for (final item in _allItems) {
      final score = _scoreItem(item, trimmed);
      if (score > 0) {
        scores[item.id] = score;
      }
    }
    final results = _allItems.where((item) => scores.containsKey(item.id)).toList();
    results.sort((a, b) {
      final diff = scores[b.id]! - scores[a.id]!;
      if (diff != 0) {
        return diff > 0 ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return results;
  }

  Future<void> clearLocalData() async {
    await _prefs.remove(_itemsKey);
    await _prefs.remove(_favoritesKey);
    await _prefs.remove(_compareKey);
    await _prefs.remove(_offersKey);
    await _prefs.remove(_wishlistKey);
    await _prefs.remove(_collectionsKey);
    await _prefs.remove(_reviewsKey);
    await _prefs.remove(_priceHistoryKey);
    await _load();
  }

  void simulateIncomingOffers() {
    _scheduleOfferSimulation();
  }

  void dispose() {
    _visibleItemsNotifier.dispose();
    _favoritesNotifier.dispose();
    _compareNotifier.dispose();
    _offersNotifier.dispose();
    _wishlistNotifier.dispose();
    _collectionsNotifier.dispose();
    _reviewsNotifier.dispose();
    _itemsStreamController.close();
    _favoritesStreamController.close();
    _compareStreamController.close();
    _wishlistStreamController.close();
    _collectionsStreamController.close();
    _offerTimer?.cancel();
  }

  void _scheduleOfferSimulation() {
    _offerTimer?.cancel();
    final allowOffers = _allItems.where((item) => item.allowOffers).toList();
    if (allowOffers.isEmpty) {
      return;
    }
    final seconds = 30 + _random.nextInt(61);
    _offerTimer = Timer(Duration(seconds: seconds), () async {
      final refreshed = _allItems.where((item) => item.allowOffers).toList();
      if (refreshed.isEmpty) {
        _scheduleOfferSimulation();
        return;
      }
      final item = refreshed[_random.nextInt(refreshed.length)];
      final basePrice = item.price ?? (20 + _random.nextDouble() * 40);
      final modifier = 0.85 + _random.nextDouble() * 0.3;
      final amount = double.parse((basePrice * modifier).toStringAsFixed(2));
      final buyer = 'Collector ${10 + _random.nextInt(90)}';
      await makeOffer(item.id, amount, buyer: buyer);
      _scheduleOfferSimulation();
    });
  }

  Future<void> _persistItems() async {
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
  }

  Future<void> _persistCollections() async {
    await _prefs.setString(
      _collectionsKey,
      Collection.encodeList(_collectionsNotifier.value),
    );
  }

  Future<void> _persistReviews() async {
    final map = _reviewsNotifier.value.map((key, value) => MapEntry(
        key, value.map((review) => review.toJson()).toList()));
    await _prefs.setString(_reviewsKey, jsonEncode(map));
  }

  Future<void> _persistPriceHistory() async {
    await _prefs.setString(_priceHistoryKey, jsonEncode(_priceHistory));
  }

  Future<void> _updateRatingForItem(String itemId, List<Review> reviews) async {
    final index = _allItems.indexWhere((element) => element.id == itemId);
    if (index == -1) {
      return;
    }
    final count = reviews.length;
    final average = count == 0
        ? 0.0
        : reviews.fold<double>(0, (acc, review) => acc + review.stars) / count;
    final updated = _allItems[index].copyWith(
      ratingCount: count,
      ratingAvg: double.parse(average.toStringAsFixed(2)),
    );
    _allItems[index] = updated;
    await _persistItems();
    _refreshVisibleItem(updated);
  }

  void _refreshVisibleItem(Item updated) {
    final list = _visibleItemsNotifier.value;
    final index = list.indexWhere((element) => element.id == updated.id);
    if (index == -1) {
      return;
    }
    final next = [...list];
    next[index] = updated;
    _visibleItemsNotifier.value = next;
    _itemsStreamController.add(next);
  }

  List<String> _deriveTags(Item item) {
    final Set<String> tags = {
      item.category,
      item.condition,
      if (item.brand != null && item.brand!.isNotEmpty) item.brand!,
    };
    tags.addAll(item.attrs.entries
        .map((entry) => '${entry.value}'.trim())
        .where((value) => value.isNotEmpty));
    tags.addAll(item.description
        .split(RegExp(r'[ ,.;!\n]'))
        .where((word) => word.length > 3)
        .take(6));
    return tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).take(12).toList();
  }

  double _scoreItem(Item item, String query) {
    double score = 0;
    final lowerName = item.name.toLowerCase();
    final lowerDesc = item.description.toLowerCase();
    final lowerCategory = item.category.toLowerCase();
    final lowerQuery = query.toLowerCase();
    if (lowerName.contains(lowerQuery)) {
      score += 2;
    }
    if (lowerDesc.contains(lowerQuery)) {
      score += 1;
    }
    if (lowerCategory.contains(lowerQuery)) {
      score += 1;
    }
    if (item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
      score += 1;
    }
    if (item.attrs.values
        .any((value) => value.toLowerCase().contains(lowerQuery))) {
      score += 0.75;
    }
    return score;
  }
}
