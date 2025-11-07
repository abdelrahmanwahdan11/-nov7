import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/items_controller.dart';
import '../../controllers/negotiation_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../features/cart/cart_controller.dart';
import '../common/snapshot_export.dart';
import '../../widgets/image_overlay_flip.dart';
import '../../widgets/price_badge.dart';
import '../../widgets/three_d_viewer.dart';
import 'widgets/negotiate_sheet.dart';
import 'widgets/variant_selector.dart';
import 'widgets/zoom_lens.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({
    super.key,
    required this.itemId,
    required this.itemsController,
    required this.cartController,
    required this.negotiationController,
    required this.appController,
  });

  final String itemId;
  final ItemsController itemsController;
  final CartController cartController;
  final NegotiationController negotiationController;
  final AppController appController;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  late final GlobalKey _snapshotKey;

  @override
  void initState() {
    super.initState();
    _snapshotKey = GlobalKey();
    widget.itemsController.trackView(widget.itemId);
  }

  Item? get item => widget.itemsController.getById(widget.itemId);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentItem = item;
    if (currentItem == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(loc.translate('emptyState'))),
      );
    }
    final effectivePrice = widget.itemsController.priceFor(currentItem.id) ?? currentItem.price;
    final selectedVariantId = widget.itemsController.selectedVariantId(currentItem.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.name),
        actions: [
          SnapshotButton(
            boundaryKey: _snapshotKey,
            itemsController: widget.itemsController,
            appController: widget.appController,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _snapshotKey,
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: () => _openOverlay(currentItem),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  child: currentItem.model3d != null
                      ? ThreeDViewer(modelUrl: currentItem.model3d!)
                      : ZoomLens(imageUrl: currentItem.images.first),
                ),
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
                    Text(currentItem.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(currentItem.description),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (effectivePrice != null)
                PriceBadge(label: '\$${effectivePrice.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 16),
          VariantSelector(
            item: currentItem,
            selectedId: selectedVariantId,
            onChanged: (id) async {
              await widget.itemsController.setVariantSelection(currentItem.id, id);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              ValueListenableBuilder<Set<String>>(
                valueListenable: widget.itemsController.favoritesListenable,
                builder: (context, favorites, _) {
                  final isFav = favorites.contains(currentItem.id);
                  return ElevatedButton.icon(
                    onPressed: () => widget.itemsController.toggleFavorite(currentItem.id),
                    icon: Icon(isFav ? IconlyBold.heart : IconlyLight.heart),
                    label: Text(isFav
                        ? loc.translate('addedToFavorites')
                        : loc.translate('addToFav')),
                  );
                },
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: widget.itemsController.compareListenable,
                builder: (context, compare, _) {
                  final inCompare = compare.contains(currentItem.id);
                  return OutlinedButton.icon(
                    onPressed: () => widget.itemsController.toggleCompare(currentItem.id),
                    icon: const Icon(IconlyLight.graph),
                    label: Text(
                      inCompare
                          ? loc.translate('addedToCompare')
                          : loc.translate('compare'),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await widget.cartController.add(currentItem.id,
                      variantId: widget.itemsController.selectedVariantId(currentItem.id) ??
                          currentItem.variants?.first.id,
                      qty: 1);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('addToCart'))),
                    );
                  }
                },
                icon: const Icon(IconlyLight.bag_2),
                label: Text(loc.translate('addToCart')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAiInfo(context),
            child: Text(loc.translate('aiInfo')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: Text(loc.translate('placeOrder')),
          ),
          const SizedBox(height: 16),
          _AttributesTable(item: currentItem),
          if (currentItem.allowOffers) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _openNegotiation(context, currentItem),
              child: Text(loc.translate('negotiate')),
            ),
          ],
        ],
      ),
    );
  }

  void _openOverlay(Item item) {
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

  Future<void> _openNegotiation(BuildContext context, Item item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: NegotiateSheet(
            itemId: item.id,
            negotiationController: widget.negotiationController,
            itemsController: widget.itemsController,
          ),
        );
      },
    );
  }

  void _showAiInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).translate('aiInfo')),
              const SizedBox(height: 12),
              // TODO: integrate real AI generated insights here.
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              const Text('Hand-crafted notes brewing...'),
            ],
          ),
        );
      },
    );
  }
}

class _AttributesTable extends StatelessWidget {
  const _AttributesTable({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: [
        ...item.attrs.entries.map(
          (entry) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(entry.key),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
