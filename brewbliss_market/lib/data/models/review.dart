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

  static List<Review> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<Review> reviews) {
    return jsonEncode(reviews.map((e) => e.toJson()).toList());
  }
}
