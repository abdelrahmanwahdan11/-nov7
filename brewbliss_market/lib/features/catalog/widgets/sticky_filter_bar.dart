import 'package:flutter/material.dart';

class StickyFilterBar extends SliverPersistentHeaderDelegate {
  StickyFilterBar({
    required this.child,
    this.minHeight = 64,
    this.maxHeight = 64,
  });

  final Widget child;
  final double minHeight;
  final double maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Align(alignment: Alignment.centerLeft, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyFilterBar oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}
