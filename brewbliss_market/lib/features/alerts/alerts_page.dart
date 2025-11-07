import 'package:flutter/material.dart';

import '../../controllers/alerts_controller.dart';
import '../../data/models/price_alert.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.alertsController});

  final AlertsController alertsController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price alerts'),
        actions: [
          IconButton(
            onPressed: alertsController.acknowledgeBadge,
            icon: const Icon(Icons.done_all_outlined),
            tooltip: 'Clear badge',
          ),
        ],
      ),
      body: ValueListenableBuilder<List<PriceAlert>>(
        valueListenable: alertsController.alertsListenable,
        builder: (context, alerts, _) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SwitchListTile(
                  value: alert.enabled,
                  onChanged: (value) => alertsController.updateAlert(
                    alert.id,
                    enabled: value,
                  ),
                  title: Text('Target ≤ ${alert.target.toStringAsFixed(2)}'),
                  subtitle: Text('Item ${alert.itemId}'),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => alertsController.removeAlert(alert.id),
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
