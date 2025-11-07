import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/items_controller.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/offer.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('offers')),
      ),
      body: ValueListenableBuilder<List<Offer>>(
        valueListenable: itemsController.offersListenable,
        builder: (context, offers, _) {
          if (offers.isEmpty) {
            return Center(child: Text(loc.translate('emptyState')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final item = itemsController.getById(offer.itemId);
              final created = offer.createdAt.toLocal();
              final timestamp =
                  '${created.year.toString().padLeft(4, '0')}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')} '
                  '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: item != null
                      ? () => Navigator.of(context).pushNamed('/item/${item.id}')
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(IconlyBold.ticket_star),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item != null)
                                    Text(
                                      item.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  Text(offer.buyer, style: Theme.of(context).textTheme.labelMedium),
                                ],
                              ),
                            ),
                            Text('\$${offer.amount.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.translate('decline'))),
                                );
                              },
                              child: Text(loc.translate('decline')),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(loc.translate('accept'))),
                                );
                              },
                              child: Text(loc.translate('accept')),
                            ),
                            const Spacer(),
                            if (item != null)
                              TextButton(
                                onPressed: () => Navigator.of(context).pushNamed('/item/${item.id}'),
                                child: Text(loc.translate('viewDetails')),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
