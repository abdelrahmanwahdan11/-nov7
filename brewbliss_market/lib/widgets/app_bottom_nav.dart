import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../controllers/app_controller.dart';
import '../core/utils/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.appController,
    this.homeKey,
    this.catalogKey,
    this.compareKey,
    this.myItemsKey,
    this.settingsKey,
  });

  final AppController appController;
  final GlobalKey? homeKey;
  final GlobalKey? catalogKey;
  final GlobalKey? compareKey;
  final GlobalKey? myItemsKey;
  final GlobalKey? settingsKey;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final labels = [
      loc.translate('forYou'),
      loc.translate('catalog'),
      loc.translate('compare'),
      loc.translate('myItems'),
      loc.translate('settings'),
    ];
    final icons = [
      KeyedSubtree(key: homeKey, child: const Icon(IconlyBold.home)),
      KeyedSubtree(key: catalogKey, child: const Icon(IconlyBold.category)),
      KeyedSubtree(key: compareKey, child: const Icon(IconlyBold.graph)),
      KeyedSubtree(key: myItemsKey, child: const Icon(IconlyBold.paper)),
      KeyedSubtree(key: settingsKey, child: const Icon(IconlyBold.setting)),
    ];
    return ValueListenableBuilder<int>(
      valueListenable: appController.bottomNavNotifier,
      builder: (context, index, _) {
        return NavigationBar(
          height: 72,
          selectedIndex: index,
          onDestinationSelected: (value) => appController.updateBottomNav(value),
          destinations: List.generate(labels.length, (i) {
            return NavigationDestination(
              icon: icons[i],
              label: labels[i],
            );
          }),
        );
      },
    );
  }
}
