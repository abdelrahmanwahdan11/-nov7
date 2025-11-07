import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../controllers/items_controller.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/app_localizations.dart';
import '../data/models/item.dart';
import '../widgets/image_overlay_flip.dart';
import '../widgets/price_badge.dart';
import '../widgets/three_d_viewer.dart';

class ItemCard3D extends StatelessWidget {
  const ItemCard3D({
    super.key,
    required this.item,
    required this.itemsController,
  });

  final Item item;
  final ItemsController itemsController;

  void _openOverlay(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'overlay',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ImageOverlayFlip(
          item: item,
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final borderRadius = BorderRadius.circular(DesignTokens.radiusLg);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => _openOverlay(context),
        onLongPress: () => Navigator.of(context).pushNamed('/item/${item.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: borderRadius,
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.25),
              width: DesignTokens.strokeThin,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: item.model3d != null
                    ? ThreeDViewer(modelUrl: item.model3d!)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        child: Image.network(
                          item.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: DesignTokens.muted.withOpacity(0.2),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.category,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.price != null)
                    PriceBadge(label: '\$${item.price!.toStringAsFixed(2)}')
                  else
                    PriceBadge(label: loc.translate('offersBadge')),
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: itemsController.favoritesListenable,
                    builder: (context, favorites, _) {
                      final isFav = favorites.contains(item.id);
                      return IconButton(
                        onPressed: () => itemsController.toggleFavorite(item.id),
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? DesignTokens.danger : null,
                        ),
                        tooltip: loc.translate(isFav ? 'removeFromFav' : 'addToFav'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, begin: 0.95, end: 1.0),
      ),
    );
  }
}
