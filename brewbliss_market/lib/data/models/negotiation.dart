import 'dart:convert';

class Negotiation {
  const Negotiation({
    required this.id,
    required this.itemId,
    required this.history,
    required this.status,
    required this.createdAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      history: (json['history'] as List<dynamic>?)
              ?.map((entry) => (entry as Map<dynamic, dynamic>)
                  .map((key, value) => MapEntry('$key', value)))
              .toList() ??
          const <Map<String, dynamic>>[],
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String itemId;
  final List<Map<String, dynamic>> history;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'history': history,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Negotiation copyWith({
    List<Map<String, dynamic>>? history,
    String? status,
  }) {
    return Negotiation(
      id: id,
      itemId: itemId,
      history: history ?? this.history,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  static List<Negotiation> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => Negotiation.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<Negotiation> negotiations) {
    return jsonEncode(negotiations.map((n) => n.toJson()).toList());
  }
}
