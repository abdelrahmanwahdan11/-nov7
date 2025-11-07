import 'dart:convert';

class Bundle {
  const Bundle({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.bundlePrice,
    this.desc,
    this.createdAt,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      id: json['id'] as String,
      name: json['name'] as String,
      itemIds: (json['itemIds'] as List<dynamic>).cast<String>(),
      bundlePrice: (json['bundlePrice'] as num).toDouble(),
      desc: json['desc'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final List<String> itemIds;
  final double bundlePrice;
  final String? desc;
  final DateTime? createdAt;

  Bundle copyWith({
    String? name,
    List<String>? itemIds,
    double? bundlePrice,
    String? desc,
    DateTime? createdAt,
  }) {
    return Bundle(
      id: id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
      bundlePrice: bundlePrice ?? this.bundlePrice,
      desc: desc ?? this.desc,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemIds': itemIds,
      'bundlePrice': bundlePrice,
      'desc': desc,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static List<Bundle> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((json) => Bundle.fromJson(json as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<Bundle> bundles) {
    return jsonEncode(bundles.map((bundle) => bundle.toJson()).toList());
  }
}
