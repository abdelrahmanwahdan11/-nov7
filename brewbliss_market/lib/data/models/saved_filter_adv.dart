import 'dart:convert';

class SavedFilterAdv {
  const SavedFilterAdv({
    required this.id,
    required this.name,
    required this.expression,
  });

  factory SavedFilterAdv.fromJson(Map<String, dynamic> json) {
    return SavedFilterAdv(
      id: json['id'] as String,
      name: json['name'] as String,
      expression: json['expression'] as String,
    );
  }

  final String id;
  final String name;
  final String expression;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expression': expression,
    };
  }

  static List<SavedFilterAdv> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => SavedFilterAdv.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<SavedFilterAdv> filters) {
    return jsonEncode(filters.map((e) => e.toJson()).toList());
  }
}
