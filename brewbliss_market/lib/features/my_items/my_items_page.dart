import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../data/models/offer.dart';
import '../../widgets/price_badge.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key, required this.itemsController, this.fabKey});

  final ItemsController itemsController;
  final GlobalKey? fabKey;

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('myItems')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.translate('sell')),
            Tab(text: loc.translate('keepOffers')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: widget.fabKey,
        onPressed: () => Navigator.of(context).pushNamed('/sell-item'),
        child: const Icon(IconlyBold.plus),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ItemsList(
            itemsController: widget.itemsController,
            filter: (item) => !(item.allowOffers),
          ),
          _ItemsList(
            itemsController: widget.itemsController,
            filter: (item) => item.allowOffers,
          ),
        ],
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.itemsController, required this.filter});

  final ItemsController itemsController;
  final bool Function(Item item) filter;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ValueListenableBuilder<List<Item>>(
      valueListenable: itemsController.visibleItemsListenable,
      builder: (context, items, _) {
        final filtered = items.where(filter).toList();
        if (filtered.isEmpty) {
          return Center(child: Text(loc.translate('emptyState')));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = filtered[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        child: Image.network(
                          item.images.first,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: DesignTokens.muted.withOpacity(0.2),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            if (item.price != null)
                              PriceBadge(label: '\$${item.price!.toStringAsFixed(2)}')
                            else
                              PriceBadge(label: loc.translate('offersBadge')),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pushNamed('/item/${item.id}'),
                        icon: const Icon(IconlyLight.arrow_right_circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<Offer>>(
                    valueListenable: itemsController.offersListenable,
                    builder: (context, offers, _) {
                      final count = offers.where((offer) => offer.itemId == item.id).length;
                      if (count == 0) {
                        return Text(loc.translate('offersBadge'));
                      }
                      return Row(
                        children: [
                          const Icon(IconlyBold.ticket_star, size: 18),
                          const SizedBox(width: 8),
                          Text('${loc.translate('offers')}: $count'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
