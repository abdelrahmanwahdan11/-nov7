import 'dart:convert';

class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.scale,
  });

  factory ThemePreset.fromJson(Map<String, dynamic> json) {
    return ThemePreset(
      id: json['id'] as String,
      name: json['name'] as String,
      primaryColor: json['primaryColor'] as int,
      scale: (json['scale'] as num).toDouble(),
    );
  }

  final String id;
  final String name;
  final int primaryColor;
  final double scale;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryColor': primaryColor,
      'scale': scale,
    };
  }

  ThemePreset copyWith({String? name, int? primaryColor, double? scale}) {
    return ThemePreset(
      id: id,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      scale: scale ?? this.scale,
    );
  }

  static List<ThemePreset> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => ThemePreset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<ThemePreset> presets) {
    return jsonEncode(presets.map((e) => e.toJson()).toList());
  }
}
