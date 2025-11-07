import 'dart:convert';

class SavedFilterAdv {
  const SavedFilterAdv({
    required this.id,
    required this.name,
    required this.expression,
    required this.createdAt,
  });

  factory SavedFilterAdv.fromJson(Map<String, dynamic> json) {
    return SavedFilterAdv(
      id: json['id'] as String,
      name: json['name'] as String,
      expression: json['expression'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final String expression;
  final DateTime createdAt;

  SavedFilterAdv copyWith({String? name, String? expression}) {
    return SavedFilterAdv(
      id: id,
      name: name ?? this.name,
      expression: expression ?? this.expression,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expression': expression,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<SavedFilterAdv> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((json) => SavedFilterAdv.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<SavedFilterAdv> filters) {
    return jsonEncode(filters.map((filter) => filter.toJson()).toList());
  }
}
