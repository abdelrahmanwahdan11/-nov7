import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/sample_data.dart';
import '../data/models/bundle.dart';
import '../data/models/collection.dart';
import '../data/models/item.dart';
import '../data/models/offer.dart';
import '../data/models/review.dart';
import '../data/models/undo_entry.dart';
import '../data/models/variant.dart';

const _itemsKey = 'items.json';
const _favoritesKey = 'favorites.ids';
const _compareKey = 'compare.ids';
const _offersKey = 'offers.json';
const _wishlistKey = 'wishlist.ids';
const _collectionsKey = 'collections.json';
const _reviewsKey = 'reviews.json';
const _priceHistoryKey = 'price_history.json';
const _variantSelectionKey = 'variant.selection';
const _metricsKey = 'interaction.metrics';
const _bundlesKey = 'bundles.json';
const _undoStackKey = 'undo_stack.json';

class ItemsController {
  ItemsController._(this._prefs) {
    _visibleItemsNotifier = ValueNotifier<List<Item>>([]);
    _favoritesNotifier = ValueNotifier<Set<String>>({});
    _compareNotifier = ValueNotifier<Set<String>>({});
    _offersNotifier = ValueNotifier<List<Offer>>([]);
    _wishlistNotifier = ValueNotifier<Set<String>>({});
    _collectionsNotifier = ValueNotifier<List<Collection>>([]);
    _reviewsNotifier = ValueNotifier<Map<String, List<Review>>>({});
    _bundlesNotifier = ValueNotifier<List<Bundle>>([]);
    _undoStackNotifier = ValueNotifier<List<UndoEntry>>([]);
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
  late final ValueNotifier<List<Bundle>> _bundlesNotifier;
  late final ValueNotifier<List<UndoEntry>> _undoStackNotifier;
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
  Map<String, String?> _variantSelections = <String, String?>{};
  Map<String, _InteractionSnapshot> _interactionMetrics =
      <String, _InteractionSnapshot>{};
  List<Bundle> _bundles = <Bundle>[];
  List<UndoEntry> _undoStack = <UndoEntry>[];

  ValueListenable<List<Item>> get visibleItemsListenable => _visibleItemsNotifier;
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;
  ValueListenable<Set<String>> get compareListenable => _compareNotifier;
  ValueListenable<List<Offer>> get offersListenable => _offersNotifier;
  ValueListenable<Set<String>> get wishlistListenable => _wishlistNotifier;
  ValueListenable<List<Collection>> get collectionsListenable => _collectionsNotifier;
  ValueListenable<Map<String, List<Review>>> get reviewsListenable => _reviewsNotifier;
  ValueListenable<List<Bundle>> get bundlesListenable => _bundlesNotifier;
  ValueListenable<List<UndoEntry>> get undoListenable => _undoStackNotifier;

  Stream<List<Item>> get itemsStream => _itemsStreamController.stream;
  Stream<Set<String>> get favoritesStream => _favoritesStreamController.stream;
  Stream<Set<String>> get compareStream => _compareStreamController.stream;
  Stream<Set<String>> get wishlistStream => _wishlistStreamController.stream;
  Stream<List<Collection>> get collectionsStream => _collectionsStreamController.stream;

  List<Collection> get collections => List<Collection>.unmodifiable(_collectionsNotifier.value);
  List<Bundle> get bundles => List<Bundle>.unmodifiable(_bundles);
  List<UndoEntry> get undoEntries => List<UndoEntry>.unmodifiable(_undoStack);
  List<Item> get allItems => List<Item>.unmodifiable(_allItems);

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
    final bundlesJson = _prefs.getString(_bundlesKey);
    _bundles = bundlesJson == null || bundlesJson.isEmpty
        ? <Bundle>[]
        : Bundle.decodeList(bundlesJson);
    _bundlesNotifier.value = [..._bundles];

    final undoJson = _prefs.getString(_undoStackKey);
    _undoStack = undoJson == null || undoJson.isEmpty
        ? <UndoEntry>[]
        : UndoEntry.decodeList(undoJson);
    _undoStackNotifier.value = [..._undoStack];

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

    final variantSelectionJson = _prefs.getString(_variantSelectionKey);
    if (variantSelectionJson != null && variantSelectionJson.isNotEmpty) {
      final decoded = jsonDecode(variantSelectionJson) as Map<String, dynamic>;
      _variantSelections = decoded.map((key, value) => MapEntry(key, value as String?));
    } else {
      _variantSelections = <String, String?>{};
    }

    final metricsJson = _prefs.getString(_metricsKey);
    if (metricsJson != null && metricsJson.isNotEmpty) {
      final decoded = jsonDecode(metricsJson) as Map<String, dynamic>;
      _interactionMetrics = decoded.map(
        (key, value) => MapEntry(
          key,
          _InteractionSnapshot.fromJson(value as Map<String, dynamic>),
        ),
      );
    } else {
      _interactionMetrics = <String, _InteractionSnapshot>{};
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
      final selection = _resolveInitialVariantSelection(item);
      final suggestedTags = _smartTagSuggestions(item);
      String? bundleId = item.bundleId;
      if (bundleId == null ||
          !_bundles.any((bundle) => bundle.id == bundleId && bundle.itemIds.contains(item.id))) {
        for (final bundle in _bundles) {
          if (bundle.itemIds.contains(item.id)) {
            bundleId = bundle.id;
            break;
          }
        }
      }
      return item.copyWith(
        priceHistory: history,
        ratingCount: ratingCount,
        ratingAvg: double.parse(ratingAvg.toStringAsFixed(2)),
        tags: item.tags.isEmpty ? _deriveTags(item) : item.tags,
        tagsSuggested: suggestedTags,
        variants: item.variants,
        variantSelectedId: selection,
        bundleId: bundleId,
      );
    }).toList();

    await _persistVariantSelections();

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
    final wasFavorite = favorites.contains(itemId);
    if (!favorites.add(itemId)) {
      favorites.remove(itemId);
    }
    _favoritesNotifier.value = favorites;
    _favoritesStreamController.add(favorites);
    await _prefs.setStringList(_favoritesKey, favorites.toList());
    if (!wasFavorite && favorites.contains(itemId)) {
      _recordInteraction(itemId, favorites: 1);
    }
  }

  Future<void> toggleCompare(String itemId) async {
    final compare = {..._compareNotifier.value};
    final wasCompared = compare.contains(itemId);
    if (compare.contains(itemId)) {
      compare.remove(itemId);
    } else if (compare.length < 3) {
      compare.add(itemId);
    }
    _compareNotifier.value = compare;
    _compareStreamController.add(compare);
    await _prefs.setStringList(_compareKey, compare.toList());
    if (!wasCompared && compare.contains(itemId)) {
      _recordInteraction(itemId, compare: 1);
    }
  }

  Future<void> addOrUpdateItem(Item item) async {
    final normalizedTags = item.tags.isEmpty ? _deriveTags(item) : item.tags;
    final normalizedHistory = item.priceHistory.isNotEmpty
        ? item.priceHistory
        : item.price != null
            ? <double>[item.price!]
            : _priceHistory[item.id] ?? <double>[];
    final suggested = item.tagsSuggested.isEmpty
        ? _smartTagSuggestions(item)
        : item.tagsSuggested;
    final normalizedItem = item.copyWith(
      tags: normalizedTags,
      priceHistory: normalizedHistory,
      tagsSuggested: suggested,
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
    final wasWishlisted = wishlist.contains(itemId);
    if (!wishlist.add(itemId)) {
      wishlist.remove(itemId);
    }
    _wishlistNotifier.value = wishlist;
    _wishlistStreamController.add(wishlist);
    await _prefs.setStringList(_wishlistKey, wishlist.toList());
    if (!wasWishlisted && wishlist.contains(itemId)) {
      _recordInteraction(itemId, wishlist: 1);
    }
  }

  bool isWishlisted(String itemId) => _wishlistNotifier.value.contains(itemId);

  String? selectedVariantId(String itemId) => _variantSelections[itemId];

  Variant? selectedVariant(String itemId) {
    final selection = selectedVariantId(itemId);
    final item = getById(itemId);
    if (selection == null || item?.variants == null) {
      return null;
    }
    try {
      return item!.variants!.firstWhere((variant) => variant.id == selection);
    } catch (_) {
      return null;
    }
  }

  Future<void> setVariantSelection(String itemId, String? variantId) async {
    if (variantId == null) {
      _variantSelections.remove(itemId);
    } else {
      _variantSelections[itemId] = variantId;
    }
    await _persistVariantSelections();
  }

  double? priceFor(String itemId, {String? variantId}) {
    final item = getById(itemId);
    if (item == null) {
      return null;
    }
    final base = item.price;
    if (base == null) {
      return null;
    }
    final selection = variantId ?? selectedVariantId(itemId);
    if (selection != null && item.variants != null) {
      try {
        final variant = item.variants!.firstWhere((element) => element.id == selection);
        return base + variant.priceDelta;
      } catch (_) {
        return base;
      }
    }
    return base;
  }

  Future<void> setDraft(String itemId, bool draft) async {
    final index = _allItems.indexWhere((element) => element.id == itemId);
    if (index == -1) return;
    final updated = _allItems[index].copyWith(draft: draft);
    _allItems[index] = updated;
    await _persistItems();
    _refreshVisibleItem(updated);
  }

  List<String> suggestedTagsFor(String itemId) {
    final item = getById(itemId);
    if (item == null) {
      return const <String>[];
    }
    return item.tagsSuggested;
  }

  List<String> smartTags(Item item) => _smartTagSuggestions(item);

  Future<Bundle> createBundle({
    required String name,
    required List<String> itemIds,
    required double price,
    String? description,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final bundle = Bundle(
      id: id,
      name: name,
      itemIds: itemIds,
      bundlePrice: double.parse(price.toStringAsFixed(2)),
      desc: description,
      createdAt: DateTime.now(),
    );
    _bundles = [bundle, ..._bundles];
    _bundlesNotifier.value = [..._bundles];
    await _persistBundles();
    for (final itemId in itemIds) {
      await assignItemToBundle(itemId, id);
    }
    return bundle;
  }

  Future<void> updateBundle(Bundle bundle) async {
    final index = _bundles.indexWhere((element) => element.id == bundle.id);
    if (index == -1) return;
    _bundles[index] = bundle;
    _bundlesNotifier.value = [..._bundles];
    await _persistBundles();
    final affectedIds = <String>{...bundle.itemIds};
    for (final item in _allItems) {
      if (item.bundleId == bundle.id && !affectedIds.contains(item.id)) {
        await assignItemToBundle(item.id, null);
      }
    }
    for (final id in bundle.itemIds) {
      await assignItemToBundle(id, bundle.id);
    }
  }

  Future<void> deleteBundle(String id) async {
    _bundles = _bundles.where((bundle) => bundle.id != id).toList();
    _bundlesNotifier.value = [..._bundles];
    await _persistBundles();
    for (var i = 0; i < _allItems.length; i++) {
      if (_allItems[i].bundleId == id) {
        final updated = _allItems[i].copyWith(bundleId: null);
        _allItems[i] = updated;
        _refreshVisibleItem(updated);
      }
    }
    await _persistItems();
  }

  List<Item> itemsForBundle(String id) {
    return _allItems.where((item) => item.bundleId == id).toList();
  }

  Future<void> assignItemToBundle(String itemId, String? bundleId) async {
    final index = _allItems.indexWhere((element) => element.id == itemId);
    if (index == -1) return;
    final updated = _allItems[index].copyWith(bundleId: bundleId);
    _allItems[index] = updated;
    await _persistItems();
    _refreshVisibleItem(updated);
  }

  List<Item> advancedFilter(String expression) {
    final parser = _FilterParser(expression);
    return _allItems.where(parser.evaluate).toList();
  }

  bool validate3D(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final lower = url.toLowerCase();
    if (!(lower.endsWith('.glb') || lower.endsWith('.gltf'))) {
      return false;
    }
    final hasScheme = lower.startsWith('http://') || lower.startsWith('https://');
    return hasScheme;
  }

  Future<void> pushUndo(UndoEntry entry) async {
    _undoStack.insert(0, entry);
    if (_undoStack.length > 20) {
      _undoStack.removeRange(20, _undoStack.length);
    }
    _undoStackNotifier.value = [..._undoStack];
    await _persistUndoStack();
  }

  Future<bool> applyUndo(UndoEntry entry) async {
    bool applied = false;
    switch (entry.action) {
      case 'item.restore':
        final data = entry.payload['item'];
        if (data is Map<String, dynamic>) {
          final restored = Item.fromJson(Map<String, dynamic>.from(data));
          await addOrUpdateItem(restored);
          applied = true;
        }
        break;
      case 'bundle.restore':
        final data = entry.payload['bundle'];
        if (data is Map<String, dynamic>) {
          final bundle = Bundle.fromJson(Map<String, dynamic>.from(data));
          final exists = _bundles.any((element) => element.id == bundle.id);
          if (exists) {
            await updateBundle(bundle);
          } else {
            _bundles = [bundle, ..._bundles];
            _bundlesNotifier.value = [..._bundles];
            await _persistBundles();
            for (final id in bundle.itemIds) {
              await assignItemToBundle(id, bundle.id);
            }
          }
          applied = true;
        }
        break;
      default:
        break;
    }
    if (applied) {
      _undoStack.removeWhere((element) => element.id == entry.id);
      _undoStackNotifier.value = [..._undoStack];
      await _persistUndoStack();
    }
    return applied;
  }

  List<Item> recommenderV2({int count = 10}) {
    if (_allItems.isEmpty) {
      return const <Item>[];
    }
    final focusIds = <String>{
      ..._favoritesNotifier.value,
      ..._wishlistNotifier.value,
      ..._compareNotifier.value,
    };
    final focusTags = <String>{};
    final focusCategories = <String>[];
    for (final id in focusIds) {
      final item = getById(id);
      if (item == null) continue;
      focusTags.addAll(item.tags);
      focusCategories.add(item.category);
    }
    final primaryCategory = _mostCommonCategory(focusCategories);
    final now = DateTime.now();
    final scored = _allItems.map((item) {
      final metrics = _interactionMetrics[item.id] ?? const _InteractionSnapshot();
      final tagOverlap = item.tags.where(focusTags.contains).length;
      final categoryBoost = primaryCategory != null && item.category == primaryCategory ? 2.0 : 0.0;
      final recency = now.difference(item.createdAt).inDays + 1;
      final recencyBoost = 3 / recency;
      final score = metrics.views * 1.0 +
          metrics.favoriteAdds * 3.0 +
          metrics.compareAdds * 2.0 +
          metrics.wishlistAdds * 2.0 +
          tagOverlap.toDouble() +
          categoryBoost +
          recencyBoost;
      return _ScoredItem(item: item, score: score);
    }).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(count).map((entry) => entry.item).toList();
  }

  void trackView(String itemId) {
    _recordInteraction(itemId, views: 1);
  }

  Future<Uint8List?> snapshotItem(GlobalKey boundaryKey) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final platformDispatcher = ui.PlatformDispatcher.instance;
    final ratio = platformDispatcher.views.isNotEmpty
        ? platformDispatcher.views.first.devicePixelRatio
        : 2.0;
    final pixelRatio = ratio.clamp(1.5, 3.0).toDouble();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

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
    _bundlesNotifier.dispose();
    _undoStackNotifier.dispose();
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

  String? _resolveInitialVariantSelection(Item item) {
    if (_variantSelections.containsKey(item.id)) {
      return _variantSelections[item.id];
    }
    if (item.variantSelectedId != null) {
      _variantSelections[item.id] = item.variantSelectedId;
      return item.variantSelectedId;
    }
    if (item.variants != null && item.variants!.isNotEmpty) {
      final first = item.variants!.first.id;
      _variantSelections[item.id] = first;
      return first;
    }
    return null;
  }

  String? _mostCommonCategory(List<String> categories) {
    if (categories.isEmpty) {
      return null;
    }
    final counts = <String, int>{};
    for (final category in categories) {
      counts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    counts.removeWhere((key, value) => value == 0);
    if (counts.isEmpty) {
      return null;
    }
    counts.entries.toList().sort((a, b) => b.value.compareTo(a.value));
    return counts.entries.first.key;
  }

  void _recordInteraction(
    String itemId, {
    int views = 0,
    int favorites = 0,
    int compare = 0,
    int wishlist = 0,
  }) {
    final current = _interactionMetrics[itemId] ?? const _InteractionSnapshot();
    final updated = current.copyWith(
      views: current.views + views,
      favoriteAdds: current.favoriteAdds + favorites,
      compareAdds: current.compareAdds + compare,
      wishlistAdds: current.wishlistAdds + wishlist,
    );
    _interactionMetrics[itemId] = updated;
    _persistMetrics();
  }

  Future<void> _persistVariantSelections() async {
    await _prefs.setString(
      _variantSelectionKey,
      jsonEncode(_variantSelections.map((key, value) => MapEntry(key, value))),
    );
  }

  Future<void> _persistMetrics() async {
    final map = _interactionMetrics.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _prefs.setString(_metricsKey, jsonEncode(map));
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

  Future<void> _persistBundles() async {
    await _prefs.setString(
      _bundlesKey,
      Bundle.encodeList(_bundles),
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

  Future<void> _persistUndoStack() async {
    await _prefs.setString(
      _undoStackKey,
      UndoEntry.encodeList(_undoStack),
    );
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

  List<String> _smartTagSuggestions(Item item) {
    final tags = <String>{..._deriveTags(item)};
    final lowerDesc = item.description.toLowerCase();
    if (lowerDesc.contains('limited')) {
      tags.add('Limited Edition');
    }
    if (item.allowOffers) {
      tags.add('Negotiable');
    }
    if (item.price != null && item.price! <= 20) {
      tags.add('Budget');
    } else if (item.price != null && item.price! >= 80) {
      tags.add('Premium');
    }
    if (item.attrs.containsKey('Material')) {
      tags.add(item.attrs['Material']!);
    }
    if (item.attrs.containsKey('Volume')) {
      tags.add(item.attrs['Volume']!);
    }
    return tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).take(15).toList();
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

class _InteractionSnapshot {
  const _InteractionSnapshot({
    this.views = 0,
    this.favoriteAdds = 0,
    this.compareAdds = 0,
    this.wishlistAdds = 0,
  });

  factory _InteractionSnapshot.fromJson(Map<String, dynamic> json) {
    return _InteractionSnapshot(
      views: json['views'] as int? ?? 0,
      favoriteAdds: json['favoriteAdds'] as int? ?? 0,
      compareAdds: json['compareAdds'] as int? ?? 0,
      wishlistAdds: json['wishlistAdds'] as int? ?? 0,
    );
  }

  final int views;
  final int favoriteAdds;
  final int compareAdds;
  final int wishlistAdds;

  _InteractionSnapshot copyWith({
    int? views,
    int? favoriteAdds,
    int? compareAdds,
    int? wishlistAdds,
  }) {
    return _InteractionSnapshot(
      views: views ?? this.views,
      favoriteAdds: favoriteAdds ?? this.favoriteAdds,
      compareAdds: compareAdds ?? this.compareAdds,
      wishlistAdds: wishlistAdds ?? this.wishlistAdds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'favoriteAdds': favoriteAdds,
      'compareAdds': compareAdds,
      'wishlistAdds': wishlistAdds,
    };
  }
}

class _ScoredItem {
  const _ScoredItem({required this.item, required this.score});

  final Item item;
  final double score;
}

class _FilterParser {
  _FilterParser(String expression) : _tokens = _tokenize(expression) {
    _root = _Parser(List<_Token>.from(_tokens)).parse();
  }

  final List<_Token> _tokens;
  late final _Node? _root;

  bool evaluate(Item item) {
    if (_tokens.isEmpty) {
      return true;
    }
    return _root?.evaluate(item) ?? true;
  }

  static List<_Token> _tokenize(String expression) {
    final tokens = <_Token>[];
    final pattern = RegExp(r'(>=|<=|==|!=|~|>|<|\(|\))|"([^"]*)"|([A-Za-z0-9_\.]+)');
    final matches = pattern.allMatches(expression);
    for (final match in matches) {
      final operatorMatch = match.group(1);
      final quoted = match.group(2);
      final word = match.group(3);
      if (operatorMatch != null) {
        if (operatorMatch == '(') {
          tokens.add(const _Token(_TokenType.lParen, '('));
        } else if (operatorMatch == ')') {
          tokens.add(const _Token(_TokenType.rParen, ')'));
        } else {
          tokens.add(_Token(_TokenType.operatorToken, operatorMatch));
        }
      } else if (quoted != null) {
        tokens.add(_Token(_TokenType.stringLiteral, quoted));
      } else if (word != null) {
        final lower = word.toLowerCase();
        if (lower == 'and') {
          tokens.add(const _Token(_TokenType.and, 'AND'));
        } else if (lower == 'or') {
          tokens.add(const _Token(_TokenType.or, 'OR'));
        } else if (lower == 'true' || lower == 'false') {
          tokens.add(_Token(_TokenType.booleanLiteral, lower));
        } else if (double.tryParse(word) != null) {
          tokens.add(_Token(_TokenType.numberLiteral, word));
        } else {
          tokens.add(_Token(_TokenType.identifier, word));
        }
      }
    }
    return tokens;
  }
}

class _Parser {
  _Parser(this._tokens);

  final List<_Token> _tokens;
  int _index = 0;

  _Node? parse() {
    if (_tokens.isEmpty) return null;
    final node = _parseExpression();
    return node;
  }

  _Node? _parseExpression() {
    var node = _parseTerm();
    while (_match(_TokenType.or)) {
      final right = _parseTerm();
      if (node != null && right != null) {
        node = _LogicalNode(node, right, isAnd: false);
      }
    }
    return node;
  }

  _Node? _parseTerm() {
    var node = _parseFactor();
    while (_match(_TokenType.and)) {
      final right = _parseFactor();
      if (node != null && right != null) {
        node = _LogicalNode(node, right, isAnd: true);
      }
    }
    return node;
  }

  _Node? _parseFactor() {
    if (_match(_TokenType.lParen)) {
      final expr = _parseExpression();
      _match(_TokenType.rParen);
      return expr;
    }
    return _parseComparison();
  }

  _Node? _parseComparison() {
    final identifierToken = _consume(_TokenType.identifier);
    if (identifierToken == null) {
      return null;
    }
    final operatorToken = _consume(_TokenType.operatorToken);
    if (operatorToken == null) {
      return null;
    }
    final valueToken = _consumeValue();
    if (valueToken == null) {
      return null;
    }
    return _ComparisonNode(
      field: identifierToken.value,
      operator: operatorToken.value,
      value: valueToken,
    );
  }

  _Token? _consumeValue() {
    if (_peekType(_TokenType.stringLiteral)) {
      return _consume(_TokenType.stringLiteral);
    }
    if (_peekType(_TokenType.numberLiteral)) {
      return _consume(_TokenType.numberLiteral);
    }
    if (_peekType(_TokenType.booleanLiteral)) {
      return _consume(_TokenType.booleanLiteral);
    }
    if (_peekType(_TokenType.identifier)) {
      return _consume(_TokenType.identifier);
    }
    return null;
  }

  bool _match(_TokenType type) {
    if (_peekType(type)) {
      _index++;
      return true;
    }
    return false;
  }

  _Token? _consume(_TokenType type) {
    if (_peekType(type)) {
      return _tokens[_index++];
    }
    return null;
  }

  bool _peekType(_TokenType type) {
    if (_index >= _tokens.length) {
      return false;
    }
    return _tokens[_index].type == type;
  }
}

abstract class _Node {
  bool evaluate(Item item);
}

class _LogicalNode extends _Node {
  _LogicalNode(this.left, this.right, {required this.isAnd});

  final _Node left;
  final _Node right;
  final bool isAnd;

  @override
  bool evaluate(Item item) {
    if (isAnd) {
      return left.evaluate(item) && right.evaluate(item);
    }
    return left.evaluate(item) || right.evaluate(item);
  }
}

class _ComparisonNode extends _Node {
  _ComparisonNode({required this.field, required this.operator, required this.value});

  final String field;
  final String operator;
  final _Token value;

  @override
  bool evaluate(Item item) {
    final resolved = _resolveField(item, field);
    final comparisonValue = _coerceValue(value);
    switch (operator) {
      case '==':
        return resolved == comparisonValue;
      case '!=':
        return resolved != comparisonValue;
      case '>':
        if (resolved is num && comparisonValue is num) {
          return resolved > comparisonValue;
        }
        return false;
      case '<':
        if (resolved is num && comparisonValue is num) {
          return resolved < comparisonValue;
        }
        return false;
      case '>=':
        if (resolved is num && comparisonValue is num) {
          return resolved >= comparisonValue;
        }
        return false;
      case '<=':
        if (resolved is num && comparisonValue is num) {
          return resolved <= comparisonValue;
        }
        return false;
      case '~':
        final haystack = _stringSetForField(item, field);
        if (haystack == null) return false;
        final needle = '${comparisonValue ?? ''}'.toLowerCase();
        return haystack.any((element) => element.contains(needle));
      default:
        return false;
    }
  }

  dynamic _coerceValue(_Token token) {
    switch (token.type) {
      case _TokenType.stringLiteral:
        return token.value;
      case _TokenType.numberLiteral:
        return double.tryParse(token.value) ?? double.nan;
      case _TokenType.booleanLiteral:
        return token.value == 'true';
      default:
        return token.value;
    }
  }

  static dynamic _resolveField(Item item, String field) {
    switch (field) {
      case 'category':
        return item.category;
      case 'price':
        return item.price;
      case 'condition':
        return item.condition;
      case 'allowOffers':
        return item.allowOffers;
      case 'brand':
        return item.brand;
      case 'draft':
        return item.draft;
      default:
        if (item.attrs.containsKey(field)) {
          return item.attrs[field];
        }
        return item.tags.firstWhere(
          (tag) => tag.toLowerCase() == field.toLowerCase(),
          orElse: () => field,
        );
    }
  }

  static Iterable<String>? _stringSetForField(Item item, String field) {
    switch (field) {
      case 'name':
        return <String>[item.name.toLowerCase()];
      case 'description':
        return <String>[item.description.toLowerCase()];
      case 'tags':
        return item.tags.map((tag) => tag.toLowerCase());
      case 'tagsSuggested':
        return item.tagsSuggested.map((tag) => tag.toLowerCase());
      default:
        if (item.attrs.containsKey(field)) {
          return <String>[item.attrs[field]!.toLowerCase()];
        }
        return null;
    }
  }
}

enum _TokenType {
  identifier,
  operatorToken,
  stringLiteral,
  numberLiteral,
  booleanLiteral,
  and,
  or,
  lParen,
  rParen,
}

class _Token {
  const _Token(this.type, this.value);

  final _TokenType type;
  final String value;
}
