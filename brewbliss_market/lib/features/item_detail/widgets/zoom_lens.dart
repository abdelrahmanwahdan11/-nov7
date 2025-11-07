import 'package:flutter/material.dart';

class ZoomLens extends StatefulWidget {
  const ZoomLens({
    super.key,
    required this.imageUrl,
    this.lensSize = 120,
    this.zoom = 2.5,
  });

  final String imageUrl;
  final double lensSize;
  final double zoom;

  @override
  State<ZoomLens> createState() => _ZoomLensState();
}

class _ZoomLensState extends State<ZoomLens> {
  Offset? _position;

  void _handleStart(DragStartDetails details, Size size) {
    setState(() => _position = _clamp(details.localPosition, size));
  }

  void _handleUpdate(DragUpdateDetails details, Size size) {
    setState(() => _position = _clamp(details.localPosition, size));
  }

  void _handleEnd() {
    setState(() => _position = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart: (details) => _handleStart(details, size),
          onPanUpdate: (details) => _handleUpdate(details, size),
          onPanEnd: (_) => _handleEnd(),
          onPanCancel: _handleEnd,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(widget.imageUrl, fit: BoxFit.cover),
              ),
              if (_position != null)
                Positioned(
                  left: _position!.dx - widget.lensSize / 2,
                  top: _position!.dy - widget.lensSize / 2,
                  child: ClipOval(
                    child: Container(
                      width: widget.lensSize,
                      height: widget.lensSize,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Transform.scale(
                        scale: widget.zoom,
                        origin: _position,
                        child: Image.network(
                          widget.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Offset _clamp(Offset raw, Size size) {
    final radius = widget.lensSize / 2;
    final dx = raw.dx.clamp(radius, size.width - radius);
    final dy = raw.dy.clamp(radius, size.height - radius);
    return Offset(dx, dy);
  }
}
