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
              return Container(
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
                        Text(offer.buyer),
                        const Spacer(),
                        Text('\$${offer.amount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(offer.createdAt.toLocal().toString()),
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
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
