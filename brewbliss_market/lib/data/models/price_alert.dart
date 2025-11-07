import 'dart:convert';

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.itemId,
    required this.target,
    required this.enabled,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      target: (json['target'] as num).toDouble(),
      enabled: json['enabled'] as bool,
    );
  }

  final String id;
  final String itemId;
  final double target;
  final bool enabled;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'target': target,
      'enabled': enabled,
    };
  }

  static List<PriceAlert> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => PriceAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<PriceAlert> alerts) {
    return jsonEncode(alerts.map((e) => e.toJson()).toList());
  }
}
