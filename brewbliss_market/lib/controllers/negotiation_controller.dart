import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/negotiation.dart';
import 'items_controller.dart';

const _negotiationsKey = 'negotiations.json';

class NegotiationController {
  NegotiationController._(this._prefs, this._itemsController) {
    _negotiationsNotifier = ValueNotifier<List<Negotiation>>(<Negotiation>[]);
    _activeNegotiation = ValueNotifier<Negotiation?>(null);
  }

  static Future<NegotiationController> init(ItemsController itemsController) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = NegotiationController._(prefs, itemsController);
    await controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  final ItemsController _itemsController;
  late final ValueNotifier<List<Negotiation>> _negotiationsNotifier;
  late final ValueNotifier<Negotiation?> _activeNegotiation;

  ValueListenable<List<Negotiation>> get negotiationsListenable => _negotiationsNotifier;
  ValueListenable<Negotiation?> get activeNegotiationListenable => _activeNegotiation;

  Future<void> start(String itemId, {double? initial}) async {
    final negotiation = Negotiation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: itemId,
      history: initial == null
          ? <Map<String, dynamic>>[]
          : <Map<String, dynamic>>[
              _entry('buyer', initial),
            ],
      status: 'open',
      createdAt: DateTime.now(),
    );
    _activeNegotiation.value = negotiation;
    await _upsert(negotiation);
  }

  Future<void> counter(double amount) async {
    final current = _activeNegotiation.value;
    if (current == null) return;
    final updated = current.copyWith(history: [...current.history, _entry('buyer', amount)]);
    _activeNegotiation.value = updated;
    await _upsert(updated);
  }

  double autoCounter(String itemId, double userOffer) {
    final item = _itemsController.getById(itemId);
    final basePrice = _itemsController.priceFor(itemId) ?? item?.price ?? 0;
    if (basePrice <= 0) {
      return userOffer;
    }
    final minimum = basePrice * 0.75;
    final step = (basePrice - userOffer).clamp(5.0, basePrice * 0.2);
    final counter = (userOffer + step).clamp(minimum, basePrice);
    return double.parse(counter.toStringAsFixed(2));
  }

  Future<void> respond(double amount) async {
    final current = _activeNegotiation.value;
    if (current == null) return;
    final updated = current.copyWith(history: [...current.history, _entry('seller', amount)]);
    _activeNegotiation.value = updated;
    await _upsert(updated);
  }

  Future<void> close(String status) async {
    final current = _activeNegotiation.value;
    if (current == null) return;
    final updated = current.copyWith(status: status);
    _activeNegotiation.value = updated;
    await _upsert(updated);
    _activeNegotiation.value = null;
  }

  Future<void> _load() async {
    final json = _prefs.getString(_negotiationsKey);
    if (json != null && json.isNotEmpty) {
      _negotiationsNotifier.value = Negotiation.decodeList(json);
    }
  }

  Future<void> _upsert(Negotiation negotiation) async {
    final list = [..._negotiationsNotifier.value];
    final index = list.indexWhere((element) => element.id == negotiation.id);
    if (index == -1) {
      list.add(negotiation);
    } else {
      list[index] = negotiation;
    }
    _negotiationsNotifier.value = list;
    await _prefs.setString(_negotiationsKey, Negotiation.encodeList(list));
  }

  Map<String, dynamic> _entry(String role, double amount) {
    return {
      'role': role,
      'amount': double.parse(amount.toStringAsFixed(2)),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void dispose() {
    _negotiationsNotifier.dispose();
    _activeNegotiation.dispose();
  }
}
