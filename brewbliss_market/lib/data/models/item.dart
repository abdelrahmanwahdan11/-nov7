import 'dart:convert';

import 'variant.dart';

class Item {
  const Item({
    required this.id,
    required this.name,
    this.brand,
    required this.images,
    this.model3d,
    this.price,
    required this.attrs,
    required this.description,
    required this.category,
    required this.condition,
    required this.allowOffers,
    this.ownerId,
    required this.createdAt,
    this.tags = const <String>[],
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.priceHistory = const <double>[],
    this.variants,
    this.variantSelectedId,
    this.draft = false,
    this.tagsSuggested = const <String>[],
    this.bundleId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      images: (json['images'] as List<dynamic>).cast<String>(),
      model3d: json['model3d'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      attrs: (json['attrs'] as Map).map((key, value) => MapEntry('$key', '$value')),
      description: json['description'] as String,
      category: json['category'] as String,
      condition: json['condition'] as String,
      allowOffers: json['allowOffers'] as bool,
      ownerId: json['ownerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const <String>[],
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      priceHistory:
          (json['priceHistory'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ??
              const <double>[],
      variants: (json['variants'] as List<dynamic>?)
          ?.map((variant) => Variant.fromJson(variant as Map<String, dynamic>))
          .toList(),
      variantSelectedId: json['variantSelectedId'] as String?,
      draft: json['draft'] as bool? ?? false,
      tagsSuggested:
          (json['tagsSuggested'] as List<dynamic>?)?.map((e) => '$e').toList() ??
              const <String>[],
      bundleId: json['bundleId'] as String?,
    );
  }

  final String id;
  final String name;
  final String? brand;
  final List<String> images;
  final String? model3d;
  final double? price;
  final Map<String, String> attrs;
  final String description;
  final String category;
  final String condition;
  final bool allowOffers;
  final String? ownerId;
  final DateTime createdAt;
  final List<String> tags;
  final double ratingAvg;
  final int ratingCount;
  final List<double> priceHistory;
  final List<Variant>? variants;
  final String? variantSelectedId;
  final bool draft;
  final List<String> tagsSuggested;
  final String? bundleId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'images': images,
      'model3d': model3d,
      'price': price,
      'attrs': attrs,
      'description': description,
      'category': category,
      'condition': condition,
      'allowOffers': allowOffers,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'priceHistory': priceHistory,
      'variants': variants?.map((variant) => variant.toJson()).toList(),
      'variantSelectedId': variantSelectedId,
      'draft': draft,
      'tagsSuggested': tagsSuggested,
      'bundleId': bundleId,
    };
  }

  Item copyWith({
    String? name,
    String? brand,
    List<String>? images,
    String? model3d,
    double? price,
    Map<String, String>? attrs,
    String? description,
    String? category,
    String? condition,
    bool? allowOffers,
    String? ownerId,
    DateTime? createdAt,
    List<String>? tags,
    double? ratingAvg,
    int? ratingCount,
    List<double>? priceHistory,
    List<Variant>? variants,
    String? variantSelectedId,
    bool? draft,
    List<String>? tagsSuggested,
    String? bundleId,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      images: images ?? this.images,
      model3d: model3d ?? this.model3d,
      price: price ?? this.price,
      attrs: attrs ?? this.attrs,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      allowOffers: allowOffers ?? this.allowOffers,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      priceHistory: priceHistory ?? this.priceHistory,
      variants: variants ?? this.variants,
      variantSelectedId: variantSelectedId ?? this.variantSelectedId,
      draft: draft ?? this.draft,
      tagsSuggested: tagsSuggested ?? this.tagsSuggested,
      bundleId: bundleId ?? this.bundleId,
    );
  }

  static List<Item> decodeList(String source) {
    final jsonList = jsonDecode(source) as List<dynamic>;
    return jsonList.map((json) => Item.fromJson(json as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<Item> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }
}
