import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../controllers/items_controller.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/app_localizations.dart';
import '../data/models/item.dart';
import '../features/home/widgets/three_d_viewer.dart';
import '../widgets/price_badge.dart';
import '../widgets/skeleton_box.dart';

class ImageOverlayFlip extends StatefulWidget {
  const ImageOverlayFlip({
    super.key,
    required this.item,
    required this.itemsController,
    required this.onClose,
  });

  final Item item;
  final ItemsController itemsController;
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
    return GestureDetector(
      onTap: _toggleSide,
      child: Container(
        color: Colors.black.withOpacity(0.75),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: _showBack ? 0.98 : 1.0,
              duration: 260.ms,
              child: AnimatedOpacity(
                duration: 260.ms,
                opacity: 1,
                child: AnimatedSwitcher(
                  duration: 500.ms,
                  transitionBuilder: (child, animation) {
                    final rotate = Tween<double>(begin: 0, end: pi).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        final value = rotate.value;
                        final isUnder = (value > pi / 2) ^ _showBack;
                        final display = Matrix4.rotationY(value);
                        if (isUnder) {
                          display.setEntry(3, 2, 0.001);
                        }
                        return Transform(
                          transform: display,
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: _showBack
                      ? _BackFace(
                          key: const ValueKey('back'),
                          item: widget.item,
                          itemsController: widget.itemsController,
                          loc: loc,
                        )
                      : _FrontFace(
                          key: const ValueKey('front'),
                          item: widget.item,
                          loc: loc,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ),
            Positioned(
              bottom: 32,
              child: Text(
                _showBack ? loc.translate('tapToFlipBack') : loc.translate('tapToFlip'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({super.key, required this.item, required this.loc});

  final Item item;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final hasModel = item.model3d != null && item.model3d!.isNotEmpty;
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: hasModel
                ? ThreeDViewer(
                    modelUrl: item.model3d!,
                    fallbackImage: item.images.isNotEmpty ? item.images.first : null,
                    semanticsLabel: item.name,
                  )
                : AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      item.images.first,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      item.brand ?? loc.translate('unknownBrand'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              PriceBadge(
                label: item.price != null
                    ? '\$${item.price!.toStringAsFixed(2)}'
                    : loc.translate('offers'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.category,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({
    super.key,
    required this.item,
    required this.itemsController,
    required this.loc,
  });

  final Item item;
  final ItemsController itemsController;
  final AppLocalizations loc;

  Future<void> _showAiInfo(BuildContext context) async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.translate('aiInfo'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const SkeletonBox(width: double.infinity, height: 12),
              const SizedBox(height: 12),
              const SkeletonBox(width: double.infinity, height: 12),
              const SizedBox(height: 12),
              Text(
                'Mock insight: this collectible pairs well with caramel notes and has ${item.attrs['Volume'] ?? 'special capacity'}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text('TODO: Integrate real AI insights.', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          ...item.attrs.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ValueListenableBuilder<Set<String>>(
                valueListenable: itemsController.favoritesListenable,
                builder: (context, favorites, _) {
                  final isFav = favorites.contains(item.id);
                  return ElevatedButton.icon(
                    onPressed: () => itemsController.toggleFavorite(item.id),
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                    label: Text(isFav ? loc.translate('removeFav') : loc.translate('addToFav')),
                  );
                },
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: itemsController.compareListenable,
                builder: (context, compare, _) {
                  final isCompare = compare.contains(item.id);
                  return OutlinedButton.icon(
                    onPressed: () => itemsController.toggleCompare(item.id),
                    icon: Icon(isCompare ? Icons.check : Icons.compare_arrows),
                    label: Text(isCompare ? loc.translate('inCompare') : loc.translate('compare')),
                  );
                },
              ),
              OutlinedButton(
                onPressed: () => _showAiInfo(context),
                child: Text(loc.translate('aiInfo')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            child: Text(loc.translate('placeOrder')),
          ),
        ],
      ),
    );
  }
}
