import 'dart:convert';

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
