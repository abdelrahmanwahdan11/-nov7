import 'dart:convert';

class Review {
  const Review({
    required this.id,
    required this.itemId,
    required this.stars,
    required this.text,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      stars: json['stars'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String itemId;
  final int stars;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'stars': stars,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Map<String, List<Review>> decodeMap(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return decoded.map((key, value) {
      final list = (value as List<dynamic>)
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
      return MapEntry(key, list);
    });
  }

  static String encodeMap(Map<String, List<Review>> map) {
    final json = map.map((key, value) => MapEntry(
        key, value.map((review) => review.toJson()).toList(growable: false)));
    return jsonEncode(json);
  }
}
