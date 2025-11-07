import 'package:flutter/material.dart';

import '../../controllers/alerts_controller.dart';
import '../../controllers/items_controller.dart';
import '../../data/models/item.dart';
import '../../data/models/price_alert.dart';
import '../common/empty_state.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({
    super.key,
    required this.alertsController,
    required this.itemsController,
  });

  final AlertsController alertsController;
  final ItemsController itemsController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price alerts'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: alertsController.badgeListenable,
            builder: (context, badge, _) {
              if (badge == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: alertsController.clearBadge,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_active_outlined),
                    Positioned(
                      right: -6,
                      top: -4,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '$badge',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<PriceAlert>>(
        valueListenable: alertsController.alertsListenable,
        builder: (context, alerts, _) {
          if (alerts.isEmpty) {
            return const EmptyState(
              title: 'No alerts yet',
              message: 'Set a target price from an item detail page.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final item = itemsController.getById(alert.itemId);
              return _AlertTile(
                alert: alert,
                item: item,
                onToggle: (enabled) => alertsController.toggleAlert(alert.id, enabled),
                onDelete: () => alertsController.deleteAlert(alert.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final PriceAlert alert;
  final Item? item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final triggered = alert.triggeredAt != null;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        title: Text(item?.name ?? 'Item ${alert.itemId}'),
        subtitle: Text('Target: ${alert.target.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.enabled,
              onChanged: onToggle,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        leading: Icon(
          triggered ? Icons.notifications_active : Icons.notifications_none,
          color: triggered ? theme.colorScheme.primary : theme.hintColor,
        ),
      ),
    );
  }
}
