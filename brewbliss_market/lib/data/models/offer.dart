import 'dart:convert';

class Offer {
  const Offer({
    required this.id,
    required this.itemId,
    required this.buyer,
    required this.amount,
    required this.createdAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      buyer: json['buyer'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String itemId;
  final String buyer;
  final double amount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemId': itemId,
        'buyer': buyer,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
      };

  static List<Offer> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<Offer> offers) {
    return jsonEncode(offers.map((e) => e.toJson()).toList());
  }
}
