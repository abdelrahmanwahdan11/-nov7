import 'dart:convert';

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.itemId,
    required this.target,
    required this.enabled,
    required this.createdAt,
    this.triggeredAt,
    this.expiresAt,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      target: (json['target'] as num).toDouble(),
      enabled: json['enabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      triggeredAt: json['triggeredAt'] == null
          ? null
          : DateTime.parse(json['triggeredAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.tryParse(json['expiresAt'] as String),
    );
  }

  final String id;
  final String itemId;
  final double target;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final DateTime? expiresAt;

  PriceAlert copyWith({
    bool? enabled,
    DateTime? triggeredAt,
    DateTime? expiresAt,
  }) {
    return PriceAlert(
      id: id,
      itemId: itemId,
      target: target,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'target': target,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'triggeredAt': triggeredAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  static List<PriceAlert> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<PriceAlert> alerts) {
    return jsonEncode(alerts.map((e) => e.toJson()).toList());
  }
}
