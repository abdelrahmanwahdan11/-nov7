import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/image_overlay_flip.dart';
import '../../widgets/price_badge.dart';
import '../../widgets/three_d_viewer.dart';

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({super.key, required this.itemId, required this.itemsController});

  final String itemId;
  final ItemsController itemsController;

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: () => _openOverlay(currentItem),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                child: currentItem.model3d != null
                    ? ThreeDViewer(modelUrl: currentItem.model3d!)
                    : Image.network(currentItem.images.first, fit: BoxFit.cover),
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
              if (currentItem.price != null)
                PriceBadge(label: '\$${currentItem.price!.toStringAsFixed(2)}'),
            ],
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
            ElevatedButton(
              onPressed: () => _makeOffer(context, currentItem),
              child: Text(loc.translate('makeOffer')),
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

  Future<void> _makeOffer(BuildContext context, Item item) async {
    final controller = TextEditingController();
    final loc = AppLocalizations.of(context);
    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('makeOffer')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '\$'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (amount != null) {
      await widget.itemsController.makeOffer(item.id, amount, buyer: 'Guest');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.translate('offers')}: ${amount.toStringAsFixed(2)}')),
        );
      }
    }
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
