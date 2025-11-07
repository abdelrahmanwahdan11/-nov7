import 'package:flutter/material.dart';

class HoverCard extends StatefulWidget {
  const HoverCard({
    super.key,
    required this.child,
    required this.overlay,
  });

  final Widget child;
  final Widget overlay;

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          widget.child,
          if (_hovering)
            Positioned(
              right: 8,
              top: 8,
              child: widget.overlay,
            ),
        ],
      ),
    );
  }
}
