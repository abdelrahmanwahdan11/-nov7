import 'dart:convert';

class UndoEntry {
  const UndoEntry({
    required this.id,
    required this.action,
    required this.payload,
    required this.timestamp,
  });

  factory UndoEntry.fromJson(Map<String, dynamic> json) {
    return UndoEntry(
      id: json['id'] as String,
      action: json['action'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  final String id;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static List<UndoEntry> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list.map((json) => UndoEntry.fromJson(json as Map<String, dynamic>)).toList();
  }

  static String encodeList(List<UndoEntry> entries) {
    return jsonEncode(entries.map((entry) => entry.toJson()).toList());
  }
}
