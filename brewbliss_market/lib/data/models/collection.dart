import 'dart:convert';

class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.itemIds,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      itemIds: (json['itemIds'] as List<dynamic>).cast<String>(),
    );
  }

  final String id;
  final String name;
  final List<String> itemIds;

  Collection copyWith({String? name, List<String>? itemIds}) {
    return Collection(
      id: id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemIds': itemIds,
    };
  }

  static List<Collection> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => Collection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<Collection> collections) {
    return jsonEncode(collections.map((e) => e.toJson()).toList());
  }
}
