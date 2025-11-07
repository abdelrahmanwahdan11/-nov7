import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../../core/utils/app_localizations.dart';
import '../cart_controller.dart';

class CartIconBadge extends StatelessWidget {
  const CartIconBadge({
    super.key,
    required this.cartController,
    this.onPressed,
  });

  final CartController cartController;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: cartController.badgeListenable,
      builder: (context, count, _) {
        final hasItems = count > 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(IconlyBold.bag_2),
              onPressed: onPressed,
              tooltip: loc.translate('cart'),
            ),
            if (hasItems)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
