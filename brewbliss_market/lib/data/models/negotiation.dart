import 'dart:convert';

class Negotiation {
  const Negotiation({
    required this.id,
    required this.itemId,
    required this.history,
    required this.status,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      history: (json['history'] as List<dynamic>)
          .map((e) => (e as Map).map((key, value) => MapEntry('$key', value)))
          .toList(),
      status: json['status'] as String,
    );
  }

  final String id;
  final String itemId;
  final List<Map<String, dynamic>> history;
  final String status;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'history': history,
      'status': status,
    };
  }

  static List<Negotiation> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => Negotiation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<Negotiation> negotiations) {
    return jsonEncode(negotiations.map((e) => e.toJson()).toList());
  }
}
