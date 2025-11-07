import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/alerts_controller.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/items_controller.dart';
import '../../controllers/negotiation_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../data/models/price_alert.dart';
import '../../data/models/bundle.dart';
import '../../data/models/undo_entry.dart';
import '../../features/cart/cart_controller.dart';
import '../common/bundle_card.dart';
import '../common/countdown_badge.dart';
import '../common/snapshot_export.dart';
import '../common/undo_bar.dart';
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
    required this.alertsController,
  });

  final String itemId;
  final ItemsController itemsController;
  final CartController cartController;
  final NegotiationController negotiationController;
  final AppController appController;
  final AlertsController alertsController;

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
          const SizedBox(height: 12),
          _PriceAlertSection(
            itemId: currentItem.id,
            alertsController: widget.alertsController,
            onCreate: () => _createPriceAlert(context, currentItem),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<List<Bundle>>( 
            valueListenable: widget.itemsController.bundlesListenable,
            builder: (context, bundles, _) {
              final bundle = _bundleForItem(currentItem, bundles);
              if (bundle == null) {
                return const SizedBox.shrink();
              }
              final items = widget.itemsController.itemsForBundle(bundle.id);
              return BundleCard(
                bundle: bundle,
                items: items,
                onAddToCart: () async {
                  for (final entry in items) {
                    await widget.cartController.add(entry.id, qty: 1);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('addToCart'))),
                    );
                  }
                },
              );
            },
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
          const SizedBox(height: 24),
          ValueListenableBuilder<List<UndoEntry>>(
            valueListenable: widget.itemsController.undoListenable,
            builder: (context, entries, _) {
              if (entries.isEmpty) {
                return const SizedBox.shrink();
              }
              final latest = entries.first;
              return UndoBar(
                message: loc.translate('undo'),
                onUndo: () async {
                  final applied = await widget.itemsController.applyUndo(latest);
                  if (applied && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.translate('undo'))),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Bundle? _bundleForItem(Item item, List<Bundle> bundles) {
    if (item.bundleId != null) {
      try {
        return bundles.firstWhere((bundle) => bundle.id == item.bundleId);
      } catch (_) {
        // fallthrough
      }
    }
    for (final bundle in bundles) {
      if (bundle.itemIds.contains(item.id)) {
        return bundle;
      }
    }
    return null;
  }

  Future<void> _createPriceAlert(BuildContext context, Item item) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: item.price?.toStringAsFixed(2) ?? '0',
    );
    final minutesController = TextEditingController(text: '30');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('priceAlert')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.translate('targetPrice')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Countdown (minutes)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.translate('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.translate('save')),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final target = double.tryParse(controller.text.trim());
    if (target == null) return;
    final alert = await widget.alertsController.createAlert(
      itemId: item.id,
      target: target,
    );
    final minutes = int.tryParse(minutesController.text.trim()) ?? 30;
    final clampedMinutes = minutes.clamp(1, 240).toInt();
    await widget.alertsController
        .setCountdown(alert.id, Duration(minutes: clampedMinutes));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.translate('priceAlert'))),
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

class _PriceAlertSection extends StatelessWidget {
  const _PriceAlertSection({
    required this.itemId,
    required this.alertsController,
    required this.onCreate,
  });

  final String itemId;
  final AlertsController alertsController;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PriceAlert>>(
      valueListenable: alertsController.alertsListenable,
      builder: (context, alerts, _) {
        final relevant = alerts.where((alert) => alert.itemId == itemId).toList();
        if (relevant.isEmpty) {
          return Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(IconlyLight.notification),
              label: Text(AppLocalizations.of(context).translate('priceAlert')),
            ),
          );
        }
        return ValueListenableBuilder<Map<String, Duration>>(
          valueListenable: alertsController.countdownsListenable,
          builder: (context, countdowns, __) {
            final active = relevant
                .map((alert) => countdowns[alert.id])
                .whereType<Duration>()
                .toList();
            final duration = active.isEmpty
                ? null
                : active.reduce((a, b) => a < b ? a : b);
            return Row(
              children: [
                if (duration != null)
                  CountdownBadge(duration: duration)
                else
                  const SizedBox.shrink(),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context).translate('priceAlert')),
                const Spacer(),
                TextButton(
                  onPressed: onCreate,
                  child: Text(MaterialLocalizations.of(context).editButtonLabel),
                ),
              ],
            );
          },
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
