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
    _alertsStreamController = StreamController<List<PriceAlert>>.broadcast();
    _badgeStreamController = StreamController<int>.broadcast();
  }

  static Future<AlertsController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = AlertsController._(prefs, itemsController);
    controller._load();
    controller._startTicker();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;
  late final ValueNotifier<List<PriceAlert>> _alertsNotifier;
  late final ValueNotifier<int> _badgeNotifier;
  late final StreamController<List<PriceAlert>> _alertsStreamController;
  late final StreamController<int> _badgeStreamController;
  Timer? _timer;

  ValueListenable<List<PriceAlert>> get alertsListenable => _alertsNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;
  Stream<List<PriceAlert>> get alertsStream => _alertsStreamController.stream;
  Stream<int> get badgeStream => _badgeStreamController.stream;

  List<PriceAlert> get alerts => _alertsNotifier.value;

  Future<void> addAlert(PriceAlert alert) async {
    final alerts = <PriceAlert>[alert, ..._alertsNotifier.value];
    _alertsNotifier.value = List<PriceAlert>.unmodifiable(alerts);
    _alertsStreamController.add(_alertsNotifier.value);
    await _persist();
  }

  Future<void> updateAlert(String id, {bool? enabled, double? target}) async {
    final alerts = <PriceAlert>[..._alertsNotifier.value];
    final index = alerts.indexWhere((element) => element.id == id);
    if (index == -1) {
      return;
    }
    final alert = alerts[index];
    alerts[index] = alert.copyWith(
      enabled: enabled ?? alert.enabled,
      triggeredAt: alert.triggeredAt,
      target: target,
    );
    _alertsNotifier.value = List<PriceAlert>.unmodifiable(alerts);
    _alertsStreamController.add(_alertsNotifier.value);
    await _persist();
  }

  Future<void> removeAlert(String id) async {
    final alerts =
        _alertsNotifier.value.where((alert) => alert.id != id).toList();
    _alertsNotifier.value = List<PriceAlert>.unmodifiable(alerts);
    _alertsStreamController.add(_alertsNotifier.value);
    await _persist();
  }

  void acknowledgeBadge() {
    _badgeNotifier.value = 0;
    _badgeStreamController.add(0);
  }

  void tick() {
    _runTick();
  }

  void _load() {
    final json = _prefs.getString(_alertsKey);
    if (json != null && json.isNotEmpty) {
      _alertsNotifier.value =
          List<PriceAlert>.unmodifiable(PriceAlert.decodeList(json));
    }
    _alertsStreamController.add(_alertsNotifier.value);
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _runTick());
  }

  void _runTick() {
    final now = DateTime.now();
    final updated = <PriceAlert>[];
    int badge = _badgeNotifier.value;
    for (final alert in _alertsNotifier.value) {
      if (!alert.enabled) {
        updated.add(alert);
        continue;
      }
      final item = _itemsController.getById(alert.itemId);
      if (item == null || item.priceHistory.isEmpty) {
        updated.add(alert);
        continue;
      }
      final latest = item.priceHistory.last;
      if (latest <= alert.target) {
        badge += 1;
        updated.add(alert.copyWith(triggeredAt: now));
      } else {
        updated.add(alert);
      }
    }
    _alertsNotifier.value = List<PriceAlert>.unmodifiable(updated);
    _alertsStreamController.add(_alertsNotifier.value);
    if (badge != _badgeNotifier.value) {
      _badgeNotifier.value = badge;
      _badgeStreamController.add(badge);
    }
    _persist();
  }

  Future<void> _persist() async {
    await _prefs.setString(_alertsKey, PriceAlert.encodeList(_alertsNotifier.value));
  }

  void dispose() {
    _timer?.cancel();
    _alertsNotifier.dispose();
    _badgeNotifier.dispose();
    _alertsStreamController.close();
    _badgeStreamController.close();
  }
}
