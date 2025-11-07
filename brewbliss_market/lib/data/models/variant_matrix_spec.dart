import 'dart:convert';

class VariantMatrixSpec {
  const VariantMatrixSpec({
    required this.id,
    required this.name,
    required this.dimensions,
    this.priceDeltaRules = const <String, double>{},
    this.createdAt,
  });

  factory VariantMatrixSpec.fromJson(Map<String, dynamic> json) {
    return VariantMatrixSpec(
      id: json['id'] as String,
      name: json['name'] as String,
      dimensions: (json['dimensions'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
      ),
      priceDeltaRules: (json['priceDeltaRules'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          const <String, double>{},
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final Map<String, List<String>> dimensions;
  final Map<String, double> priceDeltaRules;
  final DateTime? createdAt;

  VariantMatrixSpec copyWith({
    String? name,
    Map<String, List<String>>? dimensions,
    Map<String, double>? priceDeltaRules,
    DateTime? createdAt,
  }) {
    return VariantMatrixSpec(
      id: id,
      name: name ?? this.name,
      dimensions: dimensions ?? this.dimensions,
      priceDeltaRules: priceDeltaRules ?? this.priceDeltaRules,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dimensions': dimensions,
      'priceDeltaRules': priceDeltaRules,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  static List<VariantMatrixSpec> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((json) => VariantMatrixSpec.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<VariantMatrixSpec> specs) {
    return jsonEncode(specs.map((spec) => spec.toJson()).toList());
  }
}
