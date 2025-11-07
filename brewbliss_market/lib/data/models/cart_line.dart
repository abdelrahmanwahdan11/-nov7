import 'dart:convert';

class CartLine {
  const CartLine({
    required this.id,
    required this.itemId,
    this.variantId,
    this.qty = 1,
    required this.unitPrice,
    double? lineTotal,
  }) : lineTotal = lineTotal ?? unitPrice * qty;

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      variantId: json['variantId'] as String?,
      qty: json['qty'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String itemId;
  final String? variantId;
  final int qty;
  final double unitPrice;
  final double lineTotal;

  CartLine copyWith({
    int? qty,
    double? unitPrice,
    double? lineTotal,
  }) {
    return CartLine(
      id: id,
      itemId: itemId,
      variantId: variantId,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'itemId': itemId,
      'variantId': variantId,
      'qty': qty,
      'unitPrice': unitPrice,
      'lineTotal': lineTotal,
    };
  }

  static String encodeList(List<CartLine> lines) {
    return jsonEncode(lines.map((line) => line.toJson()).toList());
  }

  static List<CartLine> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((entry) => CartLine.fromJson(
            (entry as Map<dynamic, dynamic>).cast<String, dynamic>()))
        .toList();
  }
}
