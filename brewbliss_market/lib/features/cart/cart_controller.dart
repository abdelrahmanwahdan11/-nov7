import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/cart_line.dart';

const _cartKey = 'cart.json';
const _defaultTaxRate = 0.07;

class CartController extends ChangeNotifier {
  CartController._(this._prefs) {
    _linesNotifier = ValueNotifier<List<CartLine>>(<CartLine>[]);
    _badgeNotifier = ValueNotifier<int>(0);
    _linesStream = StreamController<List<CartLine>>.broadcast();
    _badgeStream = StreamController<int>.broadcast();
  }

  static Future<CartController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = CartController._(prefs);
    controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  late final ValueNotifier<List<CartLine>> _linesNotifier;
  late final ValueNotifier<int> _badgeNotifier;
  late final StreamController<List<CartLine>> _linesStream;
  late final StreamController<int> _badgeStream;

  ValueListenable<List<CartLine>> get linesListenable => _linesNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;
  Stream<List<CartLine>> get linesStream => _linesStream.stream;
  Stream<int> get badgeStream => _badgeStream.stream;

  List<CartLine> get lines => _linesNotifier.value;

  CartSummary get summary {
    final subtotal = _linesNotifier.value.fold<double>(
      0,
      (previousValue, line) => previousValue + line.lineTotal,
    );
    final tax = subtotal * _defaultTaxRate;
    return CartSummary(
      subtotal: subtotal,
      tax: tax,
      shipping: 0,
      total: subtotal + tax,
      taxRate: _defaultTaxRate,
    );
  }

  Future<void> add(
    String itemId, {
    String? variantId,
    int qty = 1,
    required double unitPrice,
  }) async {
    assert(qty > 0, 'Quantity must be positive');
    final lines = <CartLine>[..._linesNotifier.value];
    final index = lines.indexWhere(
      (line) => line.itemId == itemId && line.variantId == variantId,
    );
    if (index == -1) {
      final line = CartLine(
        id: 'cl_${DateTime.now().millisecondsSinceEpoch}',
        itemId: itemId,
        variantId: variantId,
        qty: qty,
        unitPrice: unitPrice,
      );
      lines.add(line);
    } else {
      final line = lines[index];
      final newQty = line.qty + qty;
      lines[index] = line.copyWith(
        qty: newQty,
        lineTotal: unitPrice * newQty,
      );
    }
    await _update(lines);
  }

  Future<void> updateQty(String lineId, int qty, {double? unitPrice}) async {
    if (qty <= 0) {
      await remove(lineId);
      return;
    }
    final lines = <CartLine>[..._linesNotifier.value];
    final index = lines.indexWhere((line) => line.id == lineId);
    if (index == -1) {
      return;
    }
    final line = lines[index];
    final price = unitPrice ?? line.unitPrice;
    lines[index] = line.copyWith(
      qty: qty,
      unitPrice: price,
      lineTotal: price * qty,
    );
    await _update(lines);
  }

  Future<void> remove(String lineId) async {
    final lines = _linesNotifier.value
        .where((line) => line.id != lineId)
        .toList(growable: false);
    await _update(lines);
  }

  Future<void> clear() async {
    await _update(<CartLine>[]);
  }

  Future<void> _update(List<CartLine> lines) async {
    _linesNotifier.value = List<CartLine>.unmodifiable(lines);
    _linesStream.add(_linesNotifier.value);
    final badge = lines.fold<int>(0, (value, line) => value + line.qty);
    _badgeNotifier.value = badge;
    _badgeStream.add(badge);
    await _prefs.setString(_cartKey, CartLine.encodeList(lines));
    notifyListeners();
  }

  void _load() {
    final encoded = _prefs.getString(_cartKey);
    if (encoded == null || encoded.isEmpty) {
      _linesNotifier.value = const <CartLine>[];
      _badgeNotifier.value = 0;
      return;
    }
    final lines = CartLine.decodeList(encoded);
    _linesNotifier.value = List<CartLine>.unmodifiable(lines);
    _linesStream.add(_linesNotifier.value);
    final badge = lines.fold<int>(0, (value, line) => value + line.qty);
    _badgeNotifier.value = badge;
    _badgeStream.add(badge);
  }

  @override
  void dispose() {
    _linesNotifier.dispose();
    _badgeNotifier.dispose();
    _linesStream.close();
    _badgeStream.close();
    super.dispose();
  }
}

class CartSummary {
  const CartSummary({
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.taxRate,
  });

  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final double taxRate;
}
