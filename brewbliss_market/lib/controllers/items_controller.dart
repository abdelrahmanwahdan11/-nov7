import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/pagination_mixin.dart';
import '../data/local/seed.dart';
import '../data/models/collection.dart';
import '../data/models/item.dart';
import '../data/models/offer.dart';
import '../data/models/review.dart';
import '../data/models/variant.dart';

const _itemsKey = 'items.json';
const _favoritesKey = 'favorites.ids';
const _compareKey = 'compare.ids';
const _offersKey = 'offers.json';
const _wishlistKey = 'wishlist.ids';
const _collectionsKey = 'collections.json';
const _reviewsKey = 'reviews.json';
const _priceHistoryKey = 'price_history.json';

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
    _wishlistNotifier = ValueNotifier<Set<String>>(<String>{});
    _collectionsNotifier = ValueNotifier<List<Collection>>(<Collection>[]);
    _itemsStreamController = StreamController<List<Item>>.broadcast();
    _favoritesStreamController = StreamController<Set<String>>.broadcast();
    _compareStreamController = StreamController<Set<String>>.broadcast();
    _wishlistStreamController = StreamController<Set<String>>.broadcast();
    _collectionsStreamController =
        StreamController<List<Collection>>.broadcast();
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
  late final ValueNotifier<Set<String>> _wishlistNotifier;
  late final ValueNotifier<List<Collection>> _collectionsNotifier;
  late final StreamController<List<Item>> _itemsStreamController;
  late final StreamController<Set<String>> _favoritesStreamController;
  late final StreamController<Set<String>> _compareStreamController;
  late final StreamController<Set<String>> _wishlistStreamController;
  late final StreamController<List<Collection>> _collectionsStreamController;

  final Random _random = Random();
  Timer? _offerTimer;
  List<Item> _allItems = <Item>[];
  List<Item> _filteredItems = <Item>[];
  FilterOptions _filters = FilterOptions.empty();
  SortMode _sortMode = SortMode.newest;
  String _searchQuery = '';
  int _currentPage = 0;
  bool _isPaginating = false;
  final Map<String, ValueNotifier<List<Review>>> _reviewsByItem =
      <String, ValueNotifier<List<Review>>>{};
  final Map<String, List<double>> _priceHistory = <String, List<double>>{};
  List<Collection> _collections = <Collection>[];
  final Map<String, String?> _selectedVariants = <String, String?>{};
  final Map<String, _ItemInteraction> _interactionScores =
      <String, _ItemInteraction>{};

  ValueListenable<List<Item>> get visibleItemsListenable => _visibleItemsNotifier;
  ValueListenable<bool> get loadingListenable => _isLoadingNotifier;
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;
  ValueListenable<Set<String>> get compareListenable => _compareNotifier;
  ValueListenable<List<Offer>> get offersListenable => _offersNotifier;
  ValueListenable<int> get offersBadgeListenable => _offersBadgeNotifier;
  ValueListenable<Set<String>> get wishlistListenable => _wishlistNotifier;
  ValueListenable<List<Collection>> get collectionsListenable =>
      _collectionsNotifier;

  Stream<List<Item>> get itemsStream => _itemsStreamController.stream;
  Stream<Set<String>> get favoritesStream => _favoritesStreamController.stream;
  Stream<Set<String>> get compareStream => _compareStreamController.stream;
  Stream<Set<String>> get wishlistStream => _wishlistStreamController.stream;
  Stream<List<Collection>> get collectionsStream =>
      _collectionsStreamController.stream;

  List<Item> get allItems => List<Item>.unmodifiable(_allItems);

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
    final wishlistIds = _prefs.getStringList(_wishlistKey) ?? <String>[];
    final collectionsJson = _prefs.getString(_collectionsKey);
    final reviewsJson = _prefs.getString(_reviewsKey);
    final priceHistoryJson = _prefs.getString(_priceHistoryKey);

    _favoritesNotifier.value = favIds.toSet();
    _compareNotifier.value = compareIds.toSet();
    _offersNotifier.value = offers;
    _offersBadgeNotifier.value = offers.length;
    _wishlistNotifier.value = wishlistIds.toSet();
    _wishlistStreamController.add(_wishlistNotifier.value);
    _favoritesStreamController.add(_favoritesNotifier.value);
    _compareStreamController.add(_compareNotifier.value);
    if (collectionsJson != null && collectionsJson.isNotEmpty) {
      _collections = Collection.decodeList(collectionsJson);
    } else {
      _collections = <Collection>[];
    }
    _collectionsNotifier.value = List<Collection>.unmodifiable(_collections);
    _collectionsStreamController.add(_collectionsNotifier.value);

    if (reviewsJson != null && reviewsJson.isNotEmpty) {
      final decoded = Review.decodeMap(reviewsJson);
      decoded.forEach((key, value) {
        _reviewsByItem[key] =
            ValueNotifier<List<Review>>(List<Review>.from(value));
      });
    }
    for (final item in _allItems) {
      _reviewsByItem.putIfAbsent(
        item.id,
        () => ValueNotifier<List<Review>>(<Review>[]),
      );
      if (item.priceHistory.isNotEmpty) {
        _priceHistory[item.id] = List<double>.from(item.priceHistory);
      }
    }

    if (priceHistoryJson != null && priceHistoryJson.isNotEmpty) {
      final decodedHistory =
          (jsonDecode(priceHistoryJson) as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((entry) => (entry as num).toDouble())
              .toList(),
        ),
      );
      decodedHistory.forEach((key, value) {
        _priceHistory[key] = value;
      });
    }
    _syncItemsFromHistory();

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
      if (item.tags.any((tag) => tag.toLowerCase().contains(query))) {
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
    final bool isFavorite;
    if (favorites.contains(itemId)) {
      favorites.remove(itemId);
      isFavorite = false;
    } else {
      favorites.add(itemId);
      isFavorite = true;
    }
    _favoritesNotifier.value = favorites;
    _favoritesStreamController.add(favorites);
    await _prefs.setStringList(_favoritesKey, favorites.toList());
    _bumpInteraction(itemId, favorites: isFavorite ? 1 : -1);
  }

  Future<void> toggleCompare(String itemId) async {
    final compare = <String>{..._compareNotifier.value};
    final bool added;
    if (compare.contains(itemId)) {
      compare.remove(itemId);
      added = false;
    } else if (compare.length < 3) {
      compare.add(itemId);
      added = true;
    } else {
      added = false;
    }
    _compareNotifier.value = compare;
    _compareStreamController.add(compare);
    await _prefs.setStringList(_compareKey, compare.toList());
    if (added || !compare.contains(itemId)) {
      _bumpInteraction(itemId, compare: added ? 1 : -1);
    }
  }

  Future<void> toggleWishlist(String itemId) async {
    final wishlist = <String>{..._wishlistNotifier.value};
    final bool added;
    if (wishlist.contains(itemId)) {
      wishlist.remove(itemId);
      added = false;
    } else {
      wishlist.add(itemId);
      added = true;
    }
    _wishlistNotifier.value = wishlist;
    _wishlistStreamController.add(wishlist);
    await _persistWishlist();
    _bumpInteraction(itemId, wishlist: added ? 1 : -1);
  }

  void setVariantSelection(String itemId, String? variantId) {
    _selectedVariants[itemId] = variantId;
  }

  Variant? selectedVariant(String itemId) {
    final item = getById(itemId);
    if (item == null || item.variants == null) {
      return null;
    }
    final selection = _selectedVariants[itemId] ?? item.variantSelectedId;
    if (selection == null) {
      return null;
    }
    for (final variant in item.variants!) {
      if (variant.id == selection) {
        return variant;
      }
    }
    return null;
  }

  double displayPrice(Item item) {
    Variant? variant = selectedVariant(item.id);
    if (variant == null && item.variants != null && item.variantSelectedId != null) {
      for (final entry in item.variants!) {
        if (entry.id == item.variantSelectedId) {
          variant = entry;
          break;
        }
      }
    }
    final base = item.price ?? 0;
    if (variant == null) {
      return base;
    }
    return base + variant.priceDelta;
  }

  List<String> displayImages(Item item) {
    final variant = selectedVariant(item.id);
    if (variant?.images != null && variant!.images!.isNotEmpty) {
      return variant.images!;
    }
    return item.images;
  }

  void recordView(String itemId) {
    _bumpInteraction(itemId, views: 1);
  }

  ValueListenable<List<Review>> reviewsListenable(String itemId) {
    return _reviewsByItem.putIfAbsent(
      itemId,
      () => ValueNotifier<List<Review>>(<Review>[]),
    );
  }

  Future<void> addReview(String itemId, int stars, String text) async {
    final review = Review(
      id: 'rv_${DateTime.now().millisecondsSinceEpoch}',
      itemId: itemId,
      stars: stars,
      text: text,
      createdAt: DateTime.now(),
    );
    final notifier = reviewsListenable(itemId) as ValueNotifier<List<Review>>;
    notifier.value = <Review>[review, ...notifier.value];
    await _persistReviews();

    final item = getById(itemId);
    if (item != null) {
      final totalStars = item.ratingAvg * item.ratingCount + stars;
      final newCount = item.ratingCount + 1;
      final updated = item.copyWith(
        ratingCount: newCount,
        ratingAvg: newCount == 0 ? 0 : totalStars / newCount,
      );
      await addItem(updated);
    }
  }

  Future<void> appendPricePoint(String itemId, double value) async {
    final history = _priceHistory.putIfAbsent(itemId, () => <double>[]);
    history.add(value);
    _priceHistory[itemId] = history;
    _syncItemsFromHistory();
    await _persistPriceHistory();
    await _persistItems();
  }

  List<Item> similarItems(String itemId, {int limit = 10}) {
    Item? base;
    for (final item in _allItems) {
      if (item.id == itemId) {
        base = item;
        break;
      }
    }
    if (base == null) {
      return <Item>[];
    }
    final baseTags = base.tags.toSet();
    final baseAttrs = base.attrs.entries.toList();
    final scored = <_ScoredItem>[];
    for (final item in _allItems) {
      if (item.id == base!.id) continue;
      int score = 0;
      if (item.category == base.category) {
        score += 2;
      }
      final overlap = item.tags.where(baseTags.contains).length;
      score += overlap;
      final sharedAttrs = item.attrs.entries
          .where((entry) =>
              baseAttrs.any((baseEntry) => baseEntry.key == entry.key && baseEntry.value == entry.value))
          .length;
      score += sharedAttrs;
      if (score > 0) {
        scored.add(_ScoredItem(item, score));
      }
    }
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) {
        return cmp;
      }
      return b.item.createdAt.compareTo(a.item.createdAt);
    });
    return scored.take(limit).map((entry) => entry.item).toList();
  }

  List<Item> recommenderV2({int limit = 10}) {
    if (_allItems.isEmpty) {
      return const <Item>[];
    }
    if (_interactionScores.isEmpty) {
      return _allItems.take(limit).toList();
    }
    final scored = <_ScoredItem>[];
    for (final item in _allItems) {
      final stats = _interactionScores[item.id];
      if (stats == null) {
        continue;
      }
      final tagBoost = stats.tagOverlap == 0 ? _estimateTagOverlap(item) : stats.tagOverlap;
      final score = stats.views + stats.favorites * 3 + stats.compare * 2 + stats.wishlist * 2 + tagBoost;
      if (score > 0) {
        scored.add(_ScoredItem(item, score));
      }
    }
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) {
        return cmp;
      }
      return b.item.createdAt.compareTo(a.item.createdAt);
    });
    if (scored.isEmpty) {
      return _allItems.take(limit).toList();
    }
    return scored.take(limit).map((entry) => entry.item).toList();
  }

  Future<Uint8List?> snapshotItem(GlobalKey boundaryKey) async {
    final context = boundaryKey.currentContext;
    if (context == null) {
      return null;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> addItem(Item item) async {
    final index = _allItems.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      _allItems = <Item>[item, ..._allItems];
    } else {
      _allItems[index] = item;
    }
    _priceHistory[item.id] = List<double>.from(item.priceHistory);
    _syncItemsFromHistory();
    await _persistItems();
    _rebuildFiltered();
    await paginate(reset: true);
  }

  Future<void> importItemsFromJson(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Expected a JSON array of items');
      }
      final items = decoded
          .map((entry) => Item.fromJson((entry as Map<dynamic, dynamic>)
              .map((key, value) => MapEntry('$key', value))))
          .toList()
          .cast<Item>();
      for (final item in items) {
        final index = _allItems.indexWhere((element) => element.id == item.id);
        if (index == -1) {
          _allItems = <Item>[item, ..._allItems];
        } else {
          _allItems[index] = item;
        }
        _priceHistory[item.id] = List<double>.from(item.priceHistory);
      }
      _syncItemsFromHistory();
      await _persistItems();
      _rebuildFiltered();
      await paginate(reset: true);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Unable to import JSON items');
    }
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

  List<Item> get favoritesItems =>
      _allItems.where((item) => _favoritesNotifier.value.contains(item.id)).toList();

  List<Item> get compareItems =>
      _allItems.where((item) => _compareNotifier.value.contains(item.id)).toList();

  List<Collection> get collections => List<Collection>.unmodifiable(_collections);

  Future<void> upsertCollection(Collection collection) async {
    final index = _collections.indexWhere((element) => element.id == collection.id);
    if (index == -1) {
      _collections = <Collection>[collection, ..._collections];
    } else {
      _collections[index] = collection;
    }
    _collectionsNotifier.value = List<Collection>.unmodifiable(_collections);
    _collectionsStreamController.add(_collectionsNotifier.value);
    await _persistCollections();
  }

  Future<void> removeCollection(String id) async {
    _collections = _collections.where((collection) => collection.id != id).toList();
    _collectionsNotifier.value = List<Collection>.unmodifiable(_collections);
    _collectionsStreamController.add(_collectionsNotifier.value);
    await _persistCollections();
  }

  Future<void> toggleItemInCollection(String collectionId, String itemId) async {
    final collectionIndex =
        _collections.indexWhere((collection) => collection.id == collectionId);
    if (collectionIndex == -1) {
      return;
    }
    final collection = _collections[collectionIndex];
    final items = <String>[...collection.itemIds];
    if (!items.contains(itemId)) {
      items.add(itemId);
    } else {
      items.remove(itemId);
    }
    _collections[collectionIndex] = collection.copyWith(itemIds: items);
    _collectionsNotifier.value = List<Collection>.unmodifiable(_collections);
    _collectionsStreamController.add(_collectionsNotifier.value);
    await _persistCollections();
  }

  Item? getById(String id) {
    try {
      return _allItems.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistItems() async {
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
  }

  Future<void> _persistWishlist() {
    return _prefs.setStringList(_wishlistKey, _wishlistNotifier.value.toList());
  }

  Future<void> _persistCollections() {
    return _prefs.setString(
      _collectionsKey,
      Collection.encodeList(_collections),
    );
  }

  Future<void> _persistReviews() async {
    final snapshot = <String, List<Review>>{};
    _reviewsByItem.forEach((key, notifier) {
      snapshot[key] = notifier.value;
    });
    await _prefs.setString(_reviewsKey, Review.encodeMap(snapshot));
  }

  Future<void> _persistPriceHistory() async {
    final encoded = jsonEncode(_priceHistory.map(
      (key, value) => MapEntry(key, value),
    ));
    await _prefs.setString(_priceHistoryKey, encoded);
  }

  void _bumpInteraction(
    String itemId, {
    int views = 0,
    int favorites = 0,
    int compare = 0,
    int wishlist = 0,
  }) {
    if (views == 0 && favorites == 0 && compare == 0 && wishlist == 0) {
      return;
    }
    final metrics =
        _interactionScores.putIfAbsent(itemId, () => _ItemInteraction());
    metrics
      ..views = max(0, metrics.views + views)
      ..favorites = max(0, metrics.favorites + favorites)
      ..compare = max(0, metrics.compare + compare)
      ..wishlist = max(0, metrics.wishlist + wishlist);
    final item = getById(itemId);
    if (item != null) {
      metrics.tagOverlap = max(metrics.tagOverlap, _estimateTagOverlap(item));
    }
    _interactionScores[itemId] = metrics;
  }

  int _estimateTagOverlap(Item item) {
    if (item.tags.isEmpty) {
      return 0;
    }
    final tags = item.tags.toSet();
    int best = 0;
    for (final id in _favoritesNotifier.value) {
      final favorite = getById(id);
      if (favorite == null || favorite.tags.isEmpty) {
        continue;
      }
      final overlap = favorite.tags.where(tags.contains).length;
      if (overlap > best) {
        best = overlap;
      }
    }
    return best;
  }

  void _syncItemsFromHistory() {
    if (_priceHistory.isEmpty) {
      return;
    }
    _allItems = _allItems
        .map(
          (item) => item.copyWith(
            priceHistory: _priceHistory[item.id] ?? item.priceHistory,
          ),
        )
        .toList();
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
    _wishlistNotifier.dispose();
    _collectionsNotifier.dispose();
    for (final notifier in _reviewsByItem.values) {
      notifier.dispose();
    }
    _itemsStreamController.close();
    _favoritesStreamController.close();
    _compareStreamController.close();
    _wishlistStreamController.close();
    _collectionsStreamController.close();
  }
}

class _ScoredItem {
  const _ScoredItem(this.item, this.score);

  final Item item;
  final int score;
}

class _ItemInteraction {
  _ItemInteraction({
    this.views = 0,
    this.favorites = 0,
    this.compare = 0,
    this.wishlist = 0,
    this.tagOverlap = 0,
  });

  int views;
  int favorites;
  int compare;
  int wishlist;
  int tagOverlap;
}
