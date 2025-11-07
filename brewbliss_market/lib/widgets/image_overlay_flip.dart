import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/design_tokens.dart';
import '../data/models/item.dart';
import '../core/utils/app_localizations.dart';

class ImageOverlayFlip extends StatefulWidget {
  const ImageOverlayFlip({
    super.key,
    required this.item,
    required this.onClose,
  });

  final Item item;
  final VoidCallback onClose;

  @override
  State<ImageOverlayFlip> createState() => _ImageOverlayFlipState();
}

class _ImageOverlayFlipState extends State<ImageOverlayFlip> {
  bool _showBack = false;

  void _toggleSide() {
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTap: _toggleSide,
            child: AnimatedScale(
              scale: 1,
              duration: 300.ms,
              child: AnimatedSwitcher(
                duration: 500.ms,
                transitionBuilder: (child, animation) {
                  final rotate = Tween(begin: 0.0, end: 3.14159).animate(animation);
                  return AnimatedBuilder(
                    animation: rotate,
                    child: child,
                    builder: (context, child) {
                      double value = rotate.value;
                      if (_showBack) {
                        value = 3.14159 - value;
                      }
                      return Transform(
                        transform: Matrix4.rotationY(value),
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                  );
                },
                child: _showBack
                    ? _BackFace(item: widget.item, loc: loc)
                    : _FrontFace(item: widget.item),
              ),
            ),
          ),
          Positioned(
            top: 32,
            right: 32,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({required this.item}) : super(key: const ValueKey('front'));

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                item.images.first,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({required this.item, required this.loc}) : super(key: const ValueKey('back'));

  final Item item;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...item.attrs.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${e.key}: ${e.value}'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.translate('tapCards'),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
