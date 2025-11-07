import 'dart:convert';

class Bundle {
  const Bundle({
    required this.id,
    required this.name,
    required this.itemIds,
    required this.bundlePrice,
    this.desc,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      id: json['id'] as String,
      name: json['name'] as String,
      itemIds: (json['itemIds'] as List<dynamic>).cast<String>(),
      bundlePrice: (json['bundlePrice'] as num).toDouble(),
      desc: json['desc'] as String?,
    );
  }

  final String id;
  final String name;
  final List<String> itemIds;
  final double bundlePrice;
  final String? desc;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemIds': itemIds,
      'bundlePrice': bundlePrice,
      'desc': desc,
    };
  }

  static List<Bundle> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => Bundle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<Bundle> bundles) {
    return jsonEncode(bundles.map((e) => e.toJson()).toList());
  }
}
