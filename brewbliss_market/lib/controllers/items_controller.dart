import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/sample_data.dart';
import '../data/models/item.dart';
import '../data/models/offer.dart';

const _itemsKey = 'items.json';
const _favoritesKey = 'favorites.ids';
const _compareKey = 'compare.ids';
const _offersKey = 'offers.json';

class ItemsController {
  ItemsController._(this._prefs) {
    _visibleItemsNotifier = ValueNotifier<List<Item>>([]);
    _favoritesNotifier = ValueNotifier<Set<String>>({});
    _compareNotifier = ValueNotifier<Set<String>>({});
    _offersNotifier = ValueNotifier<List<Offer>>([]);
    _itemsStreamController = StreamController<List<Item>>.broadcast();
    _favoritesStreamController = StreamController<Set<String>>.broadcast();
    _compareStreamController = StreamController<Set<String>>.broadcast();
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
  late final StreamController<List<Item>> _itemsStreamController;
  late final StreamController<Set<String>> _favoritesStreamController;
  late final StreamController<Set<String>> _compareStreamController;

  List<Item> _allItems = [];
  bool _isFetching = false;
  int _currentPage = 0;
  static const _pageSize = 12;

  ValueListenable<List<Item>> get visibleItemsListenable => _visibleItemsNotifier;
  ValueListenable<Set<String>> get favoritesListenable => _favoritesNotifier;
  ValueListenable<Set<String>> get compareListenable => _compareNotifier;
  ValueListenable<List<Offer>> get offersListenable => _offersNotifier;

  Stream<List<Item>> get itemsStream => _itemsStreamController.stream;
  Stream<Set<String>> get favoritesStream => _favoritesStreamController.stream;
  Stream<Set<String>> get compareStream => _compareStreamController.stream;

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
    final offersJson = _prefs.getString(_offersKey);
    final offers = offersJson == null || offersJson.isEmpty
        ? seedOffers
        : Offer.decodeList(offersJson);

    _favoritesNotifier.value = {...favIds};
    _compareNotifier.value = {...compareIds};
    _offersNotifier.value = [...offers];
    await refresh(resetPage: true);
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
    final index = _allItems.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      _allItems = [item, ..._allItems];
    } else {
      _allItems[index] = item;
    }
    await _prefs.setString(_itemsKey, Item.encodeList(_allItems));
    await refresh(resetPage: true);
  }

  Future<void> recordOffer(Offer offer) async {
    final offers = [..._offersNotifier.value, offer];
    _offersNotifier.value = offers;
    await _prefs.setString(_offersKey, Offer.encodeList(offers));
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
    final lower = query.toLowerCase();
    return _allItems.where((item) {
      return item.name.toLowerCase().contains(lower) ||
          item.description.toLowerCase().contains(lower) ||
          item.category.toLowerCase().contains(lower) ||
          item.condition.toLowerCase().contains(lower) ||
          item.attrs.values.any((value) => value.toLowerCase().contains(lower));
    }).toList();
  }

  Future<void> clearLocalData() async {
    await _prefs.remove(_itemsKey);
    await _prefs.remove(_favoritesKey);
    await _prefs.remove(_compareKey);
    await _prefs.remove(_offersKey);
    await _load();
  }

  void dispose() {
    _visibleItemsNotifier.dispose();
    _favoritesNotifier.dispose();
    _compareNotifier.dispose();
    _offersNotifier.dispose();
    _itemsStreamController.close();
    _favoritesStreamController.close();
    _compareStreamController.close();
  }
}
