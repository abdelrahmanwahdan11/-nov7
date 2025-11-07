import 'dart:convert';

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.filters,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String,
      query: json['query'] as String,
      filters: (json['filters'] as Map).map((key, value) => MapEntry('$key', value)),
    );
  }

  final String id;
  final String name;
  final String query;
  final Map<String, dynamic> filters;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'filters': filters,
    };
  }

  static List<SavedSearch> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => SavedSearch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<SavedSearch> searches) {
    return jsonEncode(searches.map((e) => e.toJson()).toList());
  }
}
