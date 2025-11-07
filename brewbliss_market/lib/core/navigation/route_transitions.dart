import 'package:flutter/material.dart';

PageRouteBuilder<T> fadeThroughRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 320),
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(opacity: fade, child: child);
    },
  );
}

PageRouteBuilder<T> sharedAxisRoute<T>(
  Widget page, {
  Duration duration = const Duration(milliseconds: 360),
  Axis axis = Axis.vertical,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final offsetTween = axis == Axis.horizontal
          ? Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
          : Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(position: offsetTween.animate(curve), child: child),
      );
    },
  );
}
