import 'dart:convert';

class CartLine {
  const CartLine({
    required this.id,
    required this.itemId,
    this.variantId,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.bundleId,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      variantId: json['variantId'] as String?,
      qty: json['qty'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
      bundleId: json['bundleId'] as String?,
    );
  }

  final String id;
  final String itemId;
  final String? variantId;
  final int qty;
  final double unitPrice;
  final double lineTotal;
  final String? bundleId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'variantId': variantId,
      'qty': qty,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
      'bundleId': bundleId,
    };
  }

  CartLine copyWith({int? qty, double? unitPrice, double? lineTotal}) {
    return CartLine(
      id: id,
      itemId: itemId,
      variantId: variantId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      bundleId: bundleId,
    );
  }

  static List<CartLine> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<CartLine> lines) {
    return jsonEncode(lines.map((e) => e.toJson()).toList());
  }
}
