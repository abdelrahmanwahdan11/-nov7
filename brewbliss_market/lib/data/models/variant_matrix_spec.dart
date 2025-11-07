import 'dart:convert';

class VariantMatrixSpec {
  const VariantMatrixSpec({
    required this.id,
    required this.name,
    required this.dimensions,
    this.priceDeltaRules = const {},
  });

  factory VariantMatrixSpec.fromJson(Map<String, dynamic> json) {
    return VariantMatrixSpec(
      id: json['id'] as String,
      name: json['name'] as String,
      dimensions: (json['dimensions'] as Map)
          .map((key, value) => MapEntry('$key', (value as List).cast<String>())),
      priceDeltaRules: (json['priceDeltaRules'] as Map?)?.map(
            (key, value) => MapEntry('$key', (value as num).toDouble()),
          ) ??
          const {},
    );
  }

  final String id;
  final String name;
  final Map<String, List<String>> dimensions;
  final Map<String, double> priceDeltaRules;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dimensions': dimensions,
      'priceDeltaRules': priceDeltaRules,
    };
  }

  static List<VariantMatrixSpec> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => VariantMatrixSpec.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<VariantMatrixSpec> specs) {
    return jsonEncode(specs.map((e) => e.toJson()).toList());
  }
}
