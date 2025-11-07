import 'package:flutter/foundation.dart';

import '../data/models/negotiation.dart';
import 'items_controller.dart';

class NegotiationState {
  const NegotiationState({
    required this.negotiation,
    required this.currentOffer,
    required this.counterOffer,
  });

  final Negotiation negotiation;
  final double? currentOffer;
  final double? counterOffer;
}

class NegotiationController extends ChangeNotifier {
  NegotiationController({required this.itemsController});

  final ItemsController itemsController;
  NegotiationState? _state;
  String _strategy = 'auto';

  NegotiationState? get state => _state;
  String get strategy => _strategy;

  void setStrategy(String strategy) {
    _strategy = strategy;
    notifyListeners();
  }

  Future<void> start(String itemId, {double? initial}) async {
    final negotiation = Negotiation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: itemId,
      history: [
        if (initial != null)
          {
            'type': 'buyer',
            'amount': initial,
            'timestamp': DateTime.now().toIso8601String(),
          },
      ],
      status: 'open',
    );
    _state = NegotiationState(
      negotiation: negotiation,
      currentOffer: initial,
      counterOffer: _autoCounter(itemId, initial ?? 0),
    );
    await itemsController.recordNegotiation(negotiation);
    notifyListeners();
  }

  Future<void> counter(double amount) async {
    final state = _state;
    if (state == null) return;
    final history = [
      ...state.negotiation.history,
      {
        'type': 'buyer',
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ];
    final counter = _autoCounter(state.negotiation.itemId, amount);
    final updated = Negotiation(
      id: state.negotiation.id,
      itemId: state.negotiation.itemId,
      history: [
        ...history,
        {
          'type': 'seller',
          'amount': counter,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ],
      status: 'open',
    );
    _state = NegotiationState(
      negotiation: updated,
      currentOffer: amount,
      counterOffer: counter,
    );
    await itemsController.recordNegotiation(updated);
    notifyListeners();
  }

  Future<void> close(String status) async {
    final state = _state;
    if (state == null) return;
    final updated = Negotiation(
      id: state.negotiation.id,
      itemId: state.negotiation.itemId,
      history: state.negotiation.history,
      status: status,
    );
    _state = NegotiationState(
      negotiation: updated,
      currentOffer: state.currentOffer,
      counterOffer: state.counterOffer,
    );
    await itemsController.recordNegotiation(updated);
    notifyListeners();
  }

  double _autoCounter(String itemId, double offer) {
    final item = itemsController.getById(itemId);
    if (item == null) return offer;
    final base = item.price ?? 0;
    if (_strategy == 'firm') {
      return base;
    }
    if (_strategy == 'soft') {
      return (offer + base) / 2;
    }
    final margin = base * 0.1;
    final min = base * 0.75;
    final proposed = offer + margin;
    if (proposed > base) return base;
    if (proposed < min) return min;
    return proposed;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
