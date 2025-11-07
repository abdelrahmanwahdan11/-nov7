const String _defaultCurrencySymbol = '\u0024';

String formatPrice(double? value, {String currency = _defaultCurrencySymbol}) {
  if (value == null) {
    return '--';
  }
  final fixed = value.toStringAsFixed(2);
  return currency + fixed;
}

String formatPercent(double value) {
  final fixed = (value * 100).toStringAsFixed(1);
  return fixed + '%';
}
