import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/items_controller.dart';
import '../../data/models/cart_line.dart';

const _cartKey = 'cart.json';

class CartController {
  CartController._(this._prefs, this._itemsController) {
    _linesNotifier = ValueNotifier<List<CartLine>>(<CartLine>[]);
    _badgeNotifier = ValueNotifier<int>(0);
  }

  static Future<CartController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = CartController._(prefs, itemsController);
    await controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;
  late final ValueNotifier<List<CartLine>> _linesNotifier;
  late final ValueNotifier<int> _badgeNotifier;

  ValueListenable<List<CartLine>> get linesListenable => _linesNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;

  Future<void> add(String itemId, {String? variantId, int qty = 1}) async {
    if (qty <= 0) return;
    final item = _itemsController.getById(itemId);
    if (item == null) return;
    final price = _itemsController.priceFor(itemId, variantId: variantId) ?? item.price ?? 0;
    final lines = [..._linesNotifier.value];
    final index = lines.indexWhere((line) => line.itemId == itemId && line.variantId == variantId);
    if (index == -1) {
      final line = CartLine(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemId: itemId,
        variantId: variantId,
        qty: qty,
        unitPrice: price,
      );
      lines.add(line);
    } else {
      final existing = lines[index];
      lines[index] = existing.copyWith(qty: existing.qty + qty);
    }
    _linesNotifier.value = lines;
    _updateBadge();
    await _persist();
  }

  Future<void> updateQty(String lineId, int qty) async {
    final lines = [..._linesNotifier.value];
    final index = lines.indexWhere((line) => line.id == lineId);
    if (index == -1) return;
    if (qty <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(qty: qty);
    }
    _linesNotifier.value = lines;
    _updateBadge();
    await _persist();
  }

  Future<void> remove(String lineId) async {
    final lines = _linesNotifier.value.where((line) => line.id != lineId).toList();
    _linesNotifier.value = lines;
    _updateBadge();
    await _persist();
  }

  Future<void> clear() async {
    _linesNotifier.value = const <CartLine>[];
    _updateBadge();
    await _prefs.remove(_cartKey);
  }

  CartTotals totals({double taxRate = 0.07, double shipping = 0}) {
    final subtotal = _linesNotifier.value.fold<double>(0, (value, line) => value + line.lineTotal);
    final tax = double.parse((subtotal * taxRate).toStringAsFixed(2));
    final total = subtotal + tax + shipping;
    return CartTotals(subtotal: subtotal, tax: tax, shipping: shipping, total: total);
  }

  Future<void> _load() async {
    final json = _prefs.getString(_cartKey);
    if (json != null && json.isNotEmpty) {
      _linesNotifier.value = CartLine.decodeList(json);
    }
    _updateBadge();
  }

  Future<void> _persist() async {
    final encoded = CartLine.encodeList(_linesNotifier.value);
    await _prefs.setString(_cartKey, encoded);
  }

  void _updateBadge() {
    final count = _linesNotifier.value.fold<int>(0, (value, line) => value + line.qty);
    _badgeNotifier.value = count;
  }

  void dispose() {
    _linesNotifier.dispose();
    _badgeNotifier.dispose();
  }
}

class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
  });

  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
}
