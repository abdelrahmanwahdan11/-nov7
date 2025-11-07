import 'package:flutter/material.dart';

import '../../../controllers/negotiation_controller.dart';
import '../../../controllers/items_controller.dart';
import '../../../data/models/negotiation.dart';
import '../../../core/utils/formatters.dart';

class NegotiateSheet extends StatefulWidget {
  const NegotiateSheet({
    super.key,
    required this.itemId,
    required this.negotiationController,
    required this.itemsController,
  });

  final String itemId;
  final NegotiationController negotiationController;
  final ItemsController itemsController;

  @override
  State<NegotiateSheet> createState() => _NegotiateSheetState();
}

class _NegotiateSheetState extends State<NegotiateSheet> {
  late final TextEditingController _offerController;

  @override
  void initState() {
    super.initState();
    _offerController = TextEditingController();
    widget.negotiationController.start(widget.itemId);
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.negotiationController,
      builder: (context, _) {
        final negotiation = widget.negotiationController.activeNegotiationListenable.value;
        final history = negotiation?.history ?? const <Map<String, dynamic>>[];
        final basePrice = widget.itemsController.priceFor(widget.itemId) ??
            widget.itemsController.getById(widget.itemId)?.price ??
                0;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Negotiate price', style: Theme.of(context).textTheme.titleMedium),
              if (basePrice > 0) ...[
                const SizedBox(height: 4),
                Text('List price ${formatPrice(basePrice)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 12),
              _HistoryList(history: history),
              const SizedBox(height: 12),
              TextField(
                controller: _offerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '\$'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final value = double.tryParse(_offerController.text);
                      if (value != null) {
                        widget.negotiationController.counter(value);
                        final counter = widget.negotiationController.autoCounter(widget.itemId, value);
                        widget.negotiationController.respond(counter);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Counter offer: ${formatPrice(counter)}')),
                        );
                      }
                    },
                    child: const Text('Offer'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => widget.negotiationController.close('rejected'),
                    child: const Text('Decline'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => widget.negotiationController.close('accepted'),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text('No offers yet', style: Theme.of(context).textTheme.bodySmall);
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final entry = history[index];
          final role = entry['role'] as String? ?? 'buyer';
          final amount = entry['amount'] as num? ?? 0;
          final timestamp = entry['timestamp'] as String? ?? '';
          return ListTile(
            dense: true,
            leading: Icon(role == 'buyer' ? Icons.person : Icons.storefront),
            title: Text(formatPrice(amount.toDouble())),
            subtitle: Text(timestamp),
          );
        },
      ),
    );
  }
}
