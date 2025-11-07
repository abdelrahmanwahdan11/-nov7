import 'dart:convert';

import 'user_prefs.dart';

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.prefs,
    required this.lastActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      prefs: UserPrefs.fromJson(json['prefs'] as Map<String, dynamic>),
      lastActive: DateTime.parse(json['lastActive'] as String),
    );
  }

  final String id;
  final String name;
  final UserPrefs prefs;
  final DateTime lastActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prefs': prefs.toJson(),
      'lastActive': lastActive.toIso8601String(),
    };
  }

  Profile copyWith({String? name, UserPrefs? prefs, DateTime? lastActive}) {
    return Profile(
      id: id,
      name: name ?? this.name,
      prefs: prefs ?? this.prefs,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  static List<Profile> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => Profile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<Profile> profiles) {
    return jsonEncode(profiles.map((e) => e.toJson()).toList());
  }
}
