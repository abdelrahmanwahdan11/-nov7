import 'dart:convert';

import '../../controllers/items_controller.dart';

class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.name,
    required this.query,
    this.filters = const FilterOptions(),
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      name: json['name'] as String,
      query: json['query'] as String,
      filters: FilterOptions(
        categories: ((json['filters']?['categories'] as List<dynamic>?)
                ?.map((value) => value as String)
                .toSet()) ??
            const <String>{},
        conditions: ((json['filters']?['conditions'] as List<dynamic>?)
                ?.map((value) => value as String)
                .toSet()) ??
            const <String>{},
        minPrice: (json['filters']?['minPrice'] as num?)?.toDouble(),
        maxPrice: (json['filters']?['maxPrice'] as num?)?.toDouble(),
        allowOffersOnly: json['filters']?['allowOffersOnly'] as bool? ?? false,
      ),
    );
  }

  final String id;
  final String name;
  final String query;
  final FilterOptions filters;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'query': query,
      'filters': {
        'categories': filters.categories.toList(),
        'conditions': filters.conditions.toList(),
        'minPrice': filters.minPrice,
        'maxPrice': filters.maxPrice,
        'allowOffersOnly': filters.allowOffersOnly,
      },
    };
  }

  static List<SavedSearch> decodeList(String source) {
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((entry) => SavedSearch.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<SavedSearch> searches) {
    return jsonEncode(searches.map((search) => search.toJson()).toList());
  }
}
