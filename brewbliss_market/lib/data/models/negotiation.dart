import 'dart:convert';

class Negotiation {
  const Negotiation({
    required this.id,
    required this.itemId,
    required this.history,
    this.status = NegotiationStatus.open,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      history: (json['history'] as List<dynamic>)
          .map((entry) => (entry as Map).map((key, value) => MapEntry('$key', value)))
          .toList(),
      status: NegotiationStatus.values.firstWhere(
        (value) => value.name == (json['status'] as String?),
        orElse: () => NegotiationStatus.open,
      ),
    );
  }

  final String id;
  final String itemId;
  final List<Map<String, dynamic>> history;
  final NegotiationStatus status;

  Negotiation copyWith({
    List<Map<String, dynamic>>? history,
    NegotiationStatus? status,
  }) {
    return Negotiation(
      id: id,
      itemId: itemId,
      history: history ?? this.history,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'itemId': itemId,
      'history': history,
      'status': status.name,
    };
  }

  static String encodeList(List<Negotiation> negotiations) {
    return jsonEncode(negotiations.map((negotiation) => negotiation.toJson()).toList());
  }

  static List<Negotiation> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((entry) => Negotiation.fromJson(
            (entry as Map<dynamic, dynamic>).cast<String, dynamic>()))
        .toList();
  }
}

enum NegotiationStatus { open, accepted, rejected }
