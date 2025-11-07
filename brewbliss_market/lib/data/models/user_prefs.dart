class UserPrefs {
  const UserPrefs({
    required this.lang,
    required this.dark,
    required this.primaryColor,
  });

  final String lang;
  final bool dark;
  final String primaryColor;

  UserPrefs copyWith({String? lang, bool? dark, String? primaryColor}) {
    return UserPrefs(
      lang: lang ?? this.lang,
      dark: dark ?? this.dark,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'lang': lang,
        'dark': dark,
        'primaryColor': primaryColor,
      };

  factory UserPrefs.fromJson(Map<String, dynamic> json) {
    return UserPrefs(
      lang: json['lang'] as String,
      dark: json['dark'] as bool,
      primaryColor: json['primaryColor'] as String,
    );
  }
}
