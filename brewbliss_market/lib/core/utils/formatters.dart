double _pow10(int exponent) {
  double result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

String formatPrice(
  double value, {
  String currencySymbol = r'$',
  int fractionDigits = 2,
}) {
  final factor = _pow10(fractionDigits);
  final rounded = (value * factor).round() / factor;
  return '$currencySymbol${rounded.toStringAsFixed(fractionDigits)}';
}
