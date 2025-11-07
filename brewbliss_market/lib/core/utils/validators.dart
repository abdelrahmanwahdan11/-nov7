class Validators {
  const Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\$',
    caseSensitive: false,
  );

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return message;
    }
    return null;
  }

  static String? minLength(String? value, int length, String message) {
    if (value == null || value.trim().length < length) {
      return message;
    }
    return null;
  }

  static int passwordStrengthScore(String value) {
    if (value.isEmpty) {
      return 0;
    }
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?\":{}|<>]').hasMatch(value)) score++;
    return score.clamp(0, 4);
  }

  static bool confirmPassword(String password, String confirmation) {
    return password == confirmation;
  }
}
