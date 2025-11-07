import 'dart:convert';

class Variant {
  const Variant({
    required this.id,
    required this.name,
    required this.attrs,
    this.priceDelta = 0,
    this.images,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      name: json['name'] as String,
      attrs: (json['attrs'] as Map).map((key, value) => MapEntry('$key', '$value')),
      priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0,
      images: (json['images'] as List?)?.cast<String>(),
    );
  }

  final String id;
  final String name;
  final Map<String, String> attrs;
  final double priceDelta;
  final List<String>? images;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'attrs': attrs,
      'priceDelta': priceDelta,
      'images': images,
    };
  }

  static List<Variant> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => Variant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<Variant> variants) {
    return jsonEncode(variants.map((e) => e.toJson()).toList());
  }
}
