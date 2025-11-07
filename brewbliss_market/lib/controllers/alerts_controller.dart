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
    _countdownNotifier = ValueNotifier<Map<String, Duration>>(<String, Duration>{});
    _badgeBucketsNotifier = ValueNotifier<Map<String, int>>(<String, int>{});
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
  late final ValueNotifier<Map<String, Duration>> _countdownNotifier;
  late final ValueNotifier<Map<String, int>> _badgeBucketsNotifier;
  Timer? _timer;
  int _tickCounter = 0;

  ValueListenable<List<PriceAlert>> get alertsListenable => _alertsNotifier;
  ValueListenable<int> get badgeListenable => _badgeNotifier;
  ValueListenable<Map<String, Duration>> get countdownsListenable =>
      _countdownNotifier;
  ValueListenable<Map<String, int>> get badgeBucketsListenable =>
      _badgeBucketsNotifier;

  Future<void> _load() async {
    final json = _prefs.getString(_alertsKey);
    if (json != null && json.isNotEmpty) {
      _alertsNotifier.value = PriceAlert.decodeList(json);
    }
    _recalculateBadge();
    _rebuildCountdowns();
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
    _rebuildCountdowns();
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
    _rebuildCountdowns();
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
    _rebuildCountdowns();
  }

  Future<void> setCountdown(String id, Duration duration) async {
    final alerts = _alertsNotifier.value.map((alert) {
      if (alert.id == id) {
        return alert.copyWith(expiresAt: DateTime.now().add(duration));
      }
      return alert;
    }).toList();
    _alertsNotifier.value = alerts;
    await _persist(alerts);
    _rebuildCountdowns();
  }

  Future<void> deleteAlert(String id) async {
    final alerts = _alertsNotifier.value.where((element) => element.id != id).toList();
    _alertsNotifier.value = alerts;
    await _persist(alerts);
    _rebuildCountdowns();
  }

  Future<void> clearBadge() async {
    _badgeNotifier.value = 0;
    _badgeBucketsNotifier.value = const <String, int>{};
  }

  void _startTicker() {
    _timer?.cancel();
    _tickCounter = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _tick();
    });
  }

  Future<void> _tick() async {
    _tickCounter++;
    if (_tickCounter % 45 == 0) {
      await _performPriceCheck();
    }
    _updateCountdowns();
  }

  Future<void> _performPriceCheck() async {
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
    final countdownExpired = _countdownNotifier.value.values
        .where((duration) => duration <= Duration.zero)
        .length;
    final totals = <String, int>{
      if (triggered > 0) 'price': triggered,
      if (countdownExpired > 0) 'countdown': countdownExpired,
    };
    _badgeBucketsNotifier.value = totals;
    _badgeNotifier.value = totals.values.fold(0, (prev, value) => prev + value);
  }

  void _rebuildCountdowns() {
    final now = DateTime.now();
    final durations = <String, Duration>{};
    for (final alert in _alertsNotifier.value) {
      if (alert.expiresAt != null && alert.enabled) {
        durations[alert.id] = alert.expiresAt!.difference(now);
      }
    }
    _countdownNotifier.value = durations;
    _recalculateBadge();
  }

  void _updateCountdowns() {
    if (_countdownNotifier.value.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final updated = <String, Duration>{};
    bool changed = false;
    for (final entry in _countdownNotifier.value.entries) {
      PriceAlert? alert;
      try {
        alert =
            _alertsNotifier.value.firstWhere((element) => element.id == entry.key);
      } catch (_) {
        continue;
      }
      final expiresAt = alert.expiresAt;
      if (expiresAt == null) {
        continue;
      }
      final nextDuration = expiresAt.difference(now);
      updated[entry.key] = nextDuration;
      if (_countdownNotifier.value[entry.key]?.inSeconds !=
          nextDuration.inSeconds) {
        changed = true;
      }
    }
    if (changed) {
      _countdownNotifier.value = updated;
      _recalculateBadge();
    }
  }

  void dispose() {
    _timer?.cancel();
    _alertsNotifier.dispose();
    _badgeNotifier.dispose();
    _countdownNotifier.dispose();
    _badgeBucketsNotifier.dispose();
  }
}
