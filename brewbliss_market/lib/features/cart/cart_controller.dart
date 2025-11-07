import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/items_controller.dart';
import '../../data/models/cart_line.dart';
import '../../data/models/item.dart';
import '../../data/models/variant.dart';

const _cartKey = 'cart.json';

class CartTotals {
  const CartTotals({required this.subtotal, required this.tax, required this.shipping});

  final double subtotal;
  final double tax;
  final double shipping;

  double get total => subtotal + tax + shipping;
}

class CartController extends ChangeNotifier {
  CartController._(this._prefs, this.itemsController) {
    _linesNotifier = ValueNotifier<List<CartLine>>([]);
    _badgeNotifier = ValueNotifier<int>(0);
  }

  static Future<CartController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = CartController._(prefs, itemsController);
    await controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController itemsController;
  late final ValueNotifier<List<CartLine>> _linesNotifier;
  late final ValueNotifier<int> _badgeNotifier;
  CartTotals _totals = const CartTotals(subtotal: 0, tax: 0, shipping: 0);

  ValueListenable<List<CartLine>> get linesListenable => _linesNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;
  CartTotals get totals => _totals;

  Future<void> _load() async {
    final json = _prefs.getString(_cartKey);
    if (json != null && json.isNotEmpty) {
      _linesNotifier.value = CartLine.decodeList(json);
    }
    _recalculate();
  }

  Future<void> add(String itemId, {String? variantId, int qty = 1}) async {
    final lines = [..._linesNotifier.value];
    final existingIndex = lines.indexWhere(
      (element) => element.itemId == itemId && element.variantId == variantId,
    );
    if (existingIndex == -1) {
      final price = _resolvePrice(itemId, variantId);
      final line = CartLine(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemId: itemId,
        variantId: variantId,
        qty: qty,
        unitPrice: price,
        lineTotal: price * qty,
      );
      lines.add(line);
    } else {
      final existing = lines[existingIndex];
      final newQty = existing.qty + qty;
      lines[existingIndex] = existing.copyWith(
        qty: newQty,
        lineTotal: existing.unitPrice * newQty,
      );
    }
    _linesNotifier.value = lines;
    await _persist();
  }

  Future<void> updateQty(String lineId, int qty) async {
    final lines = [..._linesNotifier.value];
    final index = lines.indexWhere((element) => element.id == lineId);
    if (index == -1) return;
    final line = lines[index];
    lines[index] = line.copyWith(qty: qty, lineTotal: line.unitPrice * qty);
    _linesNotifier.value = lines;
    await _persist();
  }

  Future<void> remove(String lineId) async {
    final lines = [..._linesNotifier.value]..removeWhere((element) => element.id == lineId);
    _linesNotifier.value = lines;
    await _persist();
  }

  Future<void> clear() async {
    _linesNotifier.value = [];
    await _persist();
  }

  double _resolvePrice(String itemId, String? variantId) {
    final Item? item = itemsController.getById(itemId);
    if (item == null) return 0;
    if (variantId == null) {
      return item.displayPrice;
    }
    final Variant? variant = item.variants.firstWhere(
      (element) => element.id == variantId,
      orElse: () => const Variant(id: 'base', name: 'Base', attrs: {}),
    );
    return (item.price ?? 0) + (variant?.priceDelta ?? 0);
  }

  Future<void> _persist() async {
    await _prefs.setString(_cartKey, CartLine.encodeList(_linesNotifier.value));
    _recalculate();
  }

  void _recalculate() {
    var subtotal = 0.0;
    for (final line in _linesNotifier.value) {
      subtotal += line.lineTotal;
    }
    final tax = double.parse((subtotal * 0.07).toStringAsFixed(2));
    const shipping = 0.0;
    _totals = CartTotals(subtotal: subtotal, tax: tax, shipping: shipping);
    _badgeNotifier.value =
        _linesNotifier.value.fold<int>(0, (sum, line) => sum + line.qty);
    notifyListeners();
  }

  @override
  void dispose() {
    _linesNotifier.dispose();
    _badgeNotifier.dispose();
    super.dispose();
  }
}
