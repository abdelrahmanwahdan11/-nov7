import 'dart:convert';

class CartLine {
  const CartLine({
    required this.id,
    required this.itemId,
    this.variantId,
    required this.qty,
    required this.unitPrice,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      variantId: json['variantId'] as String?,
      qty: json['qty'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String itemId;
  final String? variantId;
  final int qty;
  final double unitPrice;

  double get lineTotal => unitPrice * qty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'variantId': variantId,
      'qty': qty,
      'unitPrice': unitPrice,
    };
  }

  CartLine copyWith({
    int? qty,
    double? unitPrice,
    String? variantId,
  }) {
    return CartLine(
      id: id,
      itemId: itemId,
      variantId: variantId ?? this.variantId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  static List<CartLine> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => CartLine.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<CartLine> lines) {
    return jsonEncode(lines.map((line) => line.toJson()).toList());
  }
}
