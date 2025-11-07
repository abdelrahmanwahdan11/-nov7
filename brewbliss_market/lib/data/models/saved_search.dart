import 'dart:convert';

class SavedSearchFilters {
  const SavedSearchFilters({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.allowOffers,
  });

  factory SavedSearchFilters.fromJson(Map<String, dynamic> json) {
    return SavedSearchFilters(
      category: json['category'] as String?,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      allowOffers: json['allowOffers'] as bool?,
    );
  }

  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final bool? allowOffers;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'condition': condition,
      'allowOffers': allowOffers,
    };
  }
}

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.filters,
    required this.createdAt,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String,
      query: json['query'] as String,
      filters: json['filters'] == null
          ? const SavedSearchFilters()
          : SavedSearchFilters.fromJson(json['filters'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String name;
  final String query;
  final SavedSearchFilters filters;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'filters': filters.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<SavedSearch> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => SavedSearch.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<SavedSearch> searches) {
    return jsonEncode(searches.map((e) => e.toJson()).toList());
  }
}
