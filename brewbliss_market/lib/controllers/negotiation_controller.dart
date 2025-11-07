import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/negotiation.dart';

const _negotiationsKey = 'negotiations.json';

class NegotiationController extends ChangeNotifier {
  NegotiationController._(this._prefs) {
    _negotiationsNotifier = ValueNotifier<List<Negotiation>>(<Negotiation>[]);
    _streamController = StreamController<List<Negotiation>>.broadcast();
  }

  static Future<NegotiationController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = NegotiationController._(prefs);
    controller._load();
    return controller;
  }

  final SharedPreferences _prefs;
  late final ValueNotifier<List<Negotiation>> _negotiationsNotifier;
  late final StreamController<List<Negotiation>> _streamController;
  final Random _random = Random();

  ValueListenable<List<Negotiation>> get negotiationsListenable =>
      _negotiationsNotifier;
  Stream<List<Negotiation>> get negotiationsStream => _streamController.stream;

  List<Negotiation> get negotiations => _negotiationsNotifier.value;

  Negotiation? byItem(String itemId) {
    for (final negotiation in _negotiationsNotifier.value) {
      if (negotiation.itemId == itemId) {
        return negotiation;
      }
    }
    return null;
  }

  Future<Negotiation> start(
    String itemId, {
    double? initialOffer,
    double? askingPrice,
  }) async {
    final now = DateTime.now();
    final history = <Map<String, dynamic>>[];
    if (initialOffer != null) {
      history.add({
        'role': 'buyer',
        'amount': initialOffer,
        'timestamp': now.toIso8601String(),
      });
    }
    final negotiation = Negotiation(
      id: 'ng_${now.millisecondsSinceEpoch}_${_random.nextInt(9999)}',
      itemId: itemId,
      history: history,
      status: NegotiationStatus.open,
    );
    final negotiations = <Negotiation>[..._negotiationsNotifier.value];
    final existingIndex = negotiations.indexWhere((neg) => neg.itemId == itemId);
    if (existingIndex == -1) {
      negotiations.insert(0, negotiation);
    } else {
      negotiations[existingIndex] = negotiation;
    }
    await _save(negotiations);
    if (initialOffer != null && askingPrice != null) {
      final counter = _autoCounter(initialOffer, askingPrice);
      await counterOffer(negotiation.id, counter);
    }
    return negotiation;
  }

  Future<void> counterOffer(String negotiationId, double amount) async {
    final negotiations = <Negotiation>[..._negotiationsNotifier.value];
    final index = negotiations.indexWhere((neg) => neg.id == negotiationId);
    if (index == -1) {
      return;
    }
    final negotiation = negotiations[index];
    final updatedHistory = <Map<String, dynamic>>[...negotiation.history]
      ..add({
        'role': 'seller',
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    negotiations[index] = negotiation.copyWith(history: updatedHistory);
    await _save(negotiations);
  }

  Future<void> buyerCounter(String negotiationId, double amount) async {
    final negotiations = <Negotiation>[..._negotiationsNotifier.value];
    final index = negotiations.indexWhere((neg) => neg.id == negotiationId);
    if (index == -1) {
      return;
    }
    final negotiation = negotiations[index];
    final updatedHistory = <Map<String, dynamic>>[...negotiation.history]
      ..add({
        'role': 'buyer',
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    negotiations[index] = negotiation.copyWith(history: updatedHistory);
    await _save(negotiations);
  }

  Future<void> close(String negotiationId, NegotiationStatus status) async {
    final negotiations = <Negotiation>[..._negotiationsNotifier.value];
    final index = negotiations.indexWhere((neg) => neg.id == negotiationId);
    if (index == -1) {
      return;
    }
    final negotiation = negotiations[index];
    negotiations[index] = negotiation.copyWith(status: status);
    await _save(negotiations);
  }

  double _autoCounter(double offer, double askingPrice) {
    final minAcceptable = askingPrice * 0.75;
    final difference = askingPrice - offer;
    if (difference <= 0) {
      return askingPrice;
    }
    final step = difference * 0.5;
    final counter = offer + step;
    return counter.clamp(minAcceptable, askingPrice);
  }

  Future<void> _save(List<Negotiation> negotiations) async {
    _negotiationsNotifier.value = List<Negotiation>.unmodifiable(negotiations);
    _streamController.add(_negotiationsNotifier.value);
    await _prefs.setString(
      _negotiationsKey,
      Negotiation.encodeList(_negotiationsNotifier.value),
    );
    notifyListeners();
  }

  void _load() {
    final encoded = _prefs.getString(_negotiationsKey);
    if (encoded == null || encoded.isEmpty) {
      _negotiationsNotifier.value = const <Negotiation>[];
      return;
    }
    final negotiations = Negotiation.decodeList(encoded);
    _negotiationsNotifier.value = List<Negotiation>.unmodifiable(negotiations);
    _streamController.add(_negotiationsNotifier.value);
  }

  @override
  void dispose() {
    _negotiationsNotifier.dispose();
    _streamController.close();
    super.dispose();
  }
}
