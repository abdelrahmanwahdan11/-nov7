import 'package:flutter/material.dart';

import '../../controllers/items_controller.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';
import '../../widgets/item_card_3d.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('addToFav')),
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: itemsController.favoritesListenable,
        builder: (context, _, __) {
          final items = itemsController.favoritesItems;
          if (items.isEmpty) {
            return Center(child: Text(loc.translate('emptyState')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                height: 220,
                child: ItemCard3D(item: item, itemsController: itemsController),
              );
            },
          );
        },
      ),
    );
  }
}
