import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../core/utils/list_extensions.dart';
import '../../data/models/item.dart';
import '../../widgets/item_card_3d.dart';
import '../../widgets/price_badge.dart';
import '../../widgets/three_d_viewer.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.itemsController,
    required this.searchKey,
    required this.heroKey,
    required this.firstCardKey,
  });

  final ItemsController itemsController;
  final GlobalKey searchKey;
  final GlobalKey heroKey;
  final GlobalKey firstCardKey;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      widget.itemsController.fetchNextPage();
    }
  }

  Future<void> _onRefresh() async {
    await widget.itemsController.refresh(resetPage: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('appName')),
        actions: [
          IconButton(
            icon: const Icon(IconlyBold.heart),
            onPressed: () => Navigator.of(context).pushNamed('/favorites'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ValueListenableBuilder<List<Item>>(
          valueListenable: widget.itemsController.visibleItemsListenable,
          builder: (context, items, _) {
            final cards = items
                .map((item) => ItemCard3D(
                      item: item,
                      itemsController: widget.itemsController,
                    ))
                .toList();
            return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                _HomeHeader(loc: loc, theme: theme, searchKey: widget.searchKey),
                const SizedBox(height: 24),
                _HeroThreeD(item: items.firstOrNull, heroKey: widget.heroKey),
                const SizedBox(height: 24),
                _CarouselSection(items: items),
                const SizedBox(height: 24),
                Text(
                  loc.translate('forYou').toUpperCase(),
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: cards.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cards.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => SizedBox(
                            width: 200,
                            child: index == 0
                                ? KeyedSubtree(key: widget.firstCardKey, child: cards[index])
                                : cards[index],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.loc,
    required this.theme,
    required this.searchKey,
  });

  final AppLocalizations loc;
  final ThemeData theme;
  final GlobalKey searchKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: DesignTokens.primary.withOpacity(0.1),
              child: const Icon(IconlyBold.profile),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brew lover',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  loc.translate('specialOffers'),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              key: searchKey,
              icon: const Icon(IconlyLight.search),
              onPressed: () => Navigator.of(context).pushNamed('/search'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Brew Bliss\n${loc.translate('newCollection')}',
          style: theme.textTheme.displayLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PriceBadge(label: loc.translate('newCollection')),
            const SizedBox(width: 8),
            PriceBadge(label: loc.translate('specialOffers')),
          ],
        ),
      ],
    );
  }
}

class _HeroThreeD extends StatelessWidget {
  const _HeroThreeD({required this.item, required this.heroKey});

  final Item? item;
  final GlobalKey heroKey;

  @override
  Widget build(BuildContext context) {
    if (item == null || item!.model3d == null) {
      return KeyedSubtree(
        key: heroKey,
        child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          color: Theme.of(context).colorScheme.surface,
        ),
        alignment: Alignment.center,
        child: const Icon(IconlyBold.bag, size: 64),
      ),
      );
    }
    return KeyedSubtree(key: heroKey, child: ThreeDViewer(modelUrl: item!.model3d!));
  }
}

class _CarouselSection extends StatelessWidget {
  const _CarouselSection({required this.items});

  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 16),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      child: Image.network(item.images.first, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  TextButton(
                    onPressed: () {},
                    child: Text(AppLocalizations.of(context).translate('placeOrder')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
