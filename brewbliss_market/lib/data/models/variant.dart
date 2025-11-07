import 'dart:convert';

class Variant {
  const Variant({
    required this.id,
    required this.name,
    required this.attrs,
    required this.priceDelta,
    this.images,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      name: json['name'] as String,
      attrs: (json['attrs'] as Map<dynamic, dynamic>?)
              ?.map((key, value) => MapEntry('$key', '$value')) ??
          const <String, String>{},
      priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0,
      images: (json['images'] as List<dynamic>?)?.map((e) => '$e').toList(),
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

  Variant copyWith({
    String? id,
    String? name,
    Map<String, String>? attrs,
    double? priceDelta,
    List<String>? images,
  }) {
    return Variant(
      id: id ?? this.id,
      name: name ?? this.name,
      attrs: attrs ?? this.attrs,
      priceDelta: priceDelta ?? this.priceDelta,
      images: images ?? this.images,
    );
  }

  static List<Variant> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => Variant.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<Variant> variants) {
    return jsonEncode(variants.map((variant) => variant.toJson()).toList());
  }
}
