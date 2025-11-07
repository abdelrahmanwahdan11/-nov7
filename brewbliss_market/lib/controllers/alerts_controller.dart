import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/price_alert.dart';
import 'items_controller.dart';

const _alertsKey = 'price_alerts.json';

class AlertsController {
  AlertsController._(this._prefs, this._itemsController) {
    _alertsNotifier = ValueNotifier<List<PriceAlert>>(<PriceAlert>[]);
    _badgeNotifier = ValueNotifier<int>(0);
  }

  static Future<AlertsController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = AlertsController._(prefs, itemsController);
    await controller._load();
    controller._startTicker();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;

  late final ValueNotifier<List<PriceAlert>> _alertsNotifier;
  late final ValueNotifier<int> _badgeNotifier;
  Timer? _timer;

  ValueListenable<List<PriceAlert>> get alertsListenable => _alertsNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;

  Future<void> _load() async {
    final json = _prefs.getString(_alertsKey);
    if (json != null && json.isNotEmpty) {
      _alertsNotifier.value = PriceAlert.decodeList(json);
    }
    _recalculateBadge();
  }

  Future<PriceAlert> createAlert({
    required String itemId,
    required double target,
  }) async {
    final alert = PriceAlert(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: itemId,
      target: target,
      enabled: true,
      createdAt: DateTime.now(),
    );
    final alerts = [..._alertsNotifier.value, alert];
    _alertsNotifier.value = alerts;
    await _persist(alerts);
    return alert;
  }

  Future<void> updateAlert(PriceAlert alert) async {
    final alerts = _alertsNotifier.value.map((element) {
      if (element.id == alert.id) {
        return alert;
      }
      return element;
    }).toList();
    _alertsNotifier.value = alerts;
    await _persist(alerts);
  }

  Future<void> toggleAlert(String id, bool enabled) async {
    final alerts = _alertsNotifier.value.map((element) {
      if (element.id == id) {
        return element.copyWith(enabled: enabled);
      }
      return element;
    }).toList();
    _alertsNotifier.value = alerts;
    await _persist(alerts);
  }

  Future<void> deleteAlert(String id) async {
    final alerts = _alertsNotifier.value.where((element) => element.id != id).toList();
    _alertsNotifier.value = alerts;
    await _persist(alerts);
  }

  Future<void> clearBadge() async {
    _badgeNotifier.value = 0;
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) async {
      await _tick();
    });
  }

  Future<void> _tick() async {
    final alerts = [..._alertsNotifier.value];
    bool mutated = false;
    for (var i = 0; i < alerts.length; i++) {
      final alert = alerts[i];
      if (!alert.enabled) continue;
      final history = _itemsController.priceHistoryFor(alert.itemId);
      if (history.isEmpty) continue;
      final latest = history.last;
      if (latest <= alert.target) {
        alerts[i] = alert.copyWith(triggeredAt: DateTime.now());
        mutated = true;
      }
    }
    if (mutated) {
      _alertsNotifier.value = alerts;
      _recalculateBadge();
      await _persist(alerts);
    }
  }

  Future<void> _persist(List<PriceAlert> alerts) async {
    await _prefs.setString(_alertsKey, PriceAlert.encodeList(alerts));
  }

  void _recalculateBadge() {
    final triggered = _alertsNotifier.value
        .where((alert) => alert.triggeredAt != null && alert.enabled)
        .length;
    _badgeNotifier.value = triggered;
  }

  void dispose() {
    _timer?.cancel();
    _alertsNotifier.dispose();
    _badgeNotifier.dispose();
  }
}
