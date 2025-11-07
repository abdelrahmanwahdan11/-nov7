import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/price_alert.dart';
import 'items_controller.dart';

class AlertsController extends ChangeNotifier {
  AlertsController({required this.itemsController}) {
    _alertsNotifier = ValueNotifier<List<PriceAlert>>([]);
    _badgeNotifier = ValueNotifier<int>(0);
    itemsController.priceAlertsListenable.addListener(_syncAlerts);
    _syncAlerts();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _tick());
  }

  final ItemsController itemsController;
  late final ValueNotifier<List<PriceAlert>> _alertsNotifier;
  late final ValueNotifier<int> _badgeNotifier;
  Timer? _timer;
  final Set<String> _triggered = <String>{};

  ValueListenable<List<PriceAlert>> get alertsListenable => _alertsNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;

  Future<void> addAlert(String itemId, double target) async {
    final alert = PriceAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: itemId,
      target: target,
      enabled: true,
    );
    await itemsController.addPriceAlert(alert);
  }

  Future<void> toggleAlert(String id, bool enabled) async {
    final alert = _alertsNotifier.value.firstWhere((element) => element.id == id);
    await itemsController.updatePriceAlert(
      PriceAlert(id: alert.id, itemId: alert.itemId, target: alert.target, enabled: enabled),
    );
  }

  Future<void> removeAlert(String id) async {
    await itemsController.removePriceAlert(id);
    _triggered.remove(id);
    _updateBadge();
  }

  void _syncAlerts() {
    _alertsNotifier.value = itemsController.priceAlertsListenable.value;
    _updateBadge();
  }

  void _tick() {
    if (_alertsNotifier.value.isEmpty) return;
    for (final alert in _alertsNotifier.value) {
      if (!alert.enabled) continue;
      final item = itemsController.getById(alert.itemId);
      if (item == null) continue;
      final history = itemsController.priceHistoryListenable.value[alert.itemId] ??
          item.priceHistory;
      if (history.isEmpty) continue;
      final last = history.last;
      if (last <= alert.target) {
        _triggered.add(alert.id);
      }
    }
    _updateBadge();
  }

  void _updateBadge() {
    _badgeNotifier.value = _triggered.length;
  }

  @override
  void dispose() {
    itemsController.priceAlertsListenable.removeListener(_syncAlerts);
    _timer?.cancel();
    _alertsNotifier.dispose();
    _badgeNotifier.dispose();
    super.dispose();
  }
}
