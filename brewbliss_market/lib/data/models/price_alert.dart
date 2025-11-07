import 'dart:convert';

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.itemId,
    required this.target,
    this.enabled = true,
    this.triggeredAt,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      target: (json['target'] as num).toDouble(),
      enabled: json['enabled'] as bool? ?? true,
      triggeredAt: json['triggeredAt'] == null
          ? null
          : DateTime.parse(json['triggeredAt'] as String),
    );
  }

  final String id;
  final String itemId;
  final double target;
  final bool enabled;
  final DateTime? triggeredAt;

  PriceAlert copyWith({
    bool? enabled,
    DateTime? triggeredAt,
    double? target,
  }) {
    return PriceAlert(
      id: id,
      itemId: itemId,
      target: target ?? this.target,
      enabled: enabled ?? this.enabled,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'target': target,
      'enabled': enabled,
      'triggeredAt': triggeredAt?.toIso8601String(),
    };
  }

  static List<PriceAlert> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((json) => PriceAlert.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<PriceAlert> alerts) {
    return jsonEncode(alerts.map((alert) => alert.toJson()).toList());
  }
}
