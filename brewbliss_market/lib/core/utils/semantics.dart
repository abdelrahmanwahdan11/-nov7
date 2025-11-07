import 'package:flutter/widgets.dart';

class SemanticsHelper {
  const SemanticsHelper._();

  static Widget labeled({required String label, required Widget child}) {
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }

  static Widget button({required String label, required VoidCallback? onPressed, required Widget child}) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: ExcludeSemantics(child: child),
    );
  }
}
