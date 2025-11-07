import 'package:flutter/material.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/items_controller.dart';
import '../../controllers/search_controller.dart';
import '../../core/utils/app_localizations.dart';
import '../../widgets/app_bottom_nav.dart';
import '../catalog/catalog_page.dart';
import '../compare/compare_page.dart';
import '../home/home_page.dart';
import '../my_items/my_items_page.dart';
import '../settings/settings_page.dart';
import '../cart/cart_controller.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.appController,
    required this.itemsController,
    required this.cartController,
    required this.searchController,
  });

  final AppController appController;
  final ItemsController itemsController;
  final CartController cartController;
  final SearchController searchController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final List<Widget> _pages;
  late final GlobalKey _searchKey;
  late final GlobalKey _heroKey;
  late final GlobalKey _firstCardKey;
  late final GlobalKey _compareKey;
  late final GlobalKey _fabKey;
  TutorialCoachMark? _coachMark;
  VoidCallback? _coachListener;
  bool _coachScheduled = false;

  @override
  void initState() {
    super.initState();
    _searchKey = GlobalKey();
    _heroKey = GlobalKey();
    _firstCardKey = GlobalKey();
    _compareKey = GlobalKey();
    _fabKey = GlobalKey();
    _pages = [
      HomePage(
        itemsController: widget.itemsController,
        cartController: widget.cartController,
        searchKey: _searchKey,
        heroKey: _heroKey,
        firstCardKey: _firstCardKey,
      ),
      CatalogPage(
        itemsController: widget.itemsController,
        searchController: widget.searchController,
        cartController: widget.cartController,
      ),
      ComparePage(
        itemsController: widget.itemsController,
        cartController: widget.cartController,
      ),
      MyItemsPage(itemsController: widget.itemsController, fabKey: _fabKey),
      SettingsPage(appController: widget.appController, itemsController: widget.itemsController),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCoach());
  }

  @override
  void dispose() {
    _coachMark?.finish();
    if (_coachListener != null) {
      widget.itemsController.visibleItemsListenable.removeListener(_coachListener!);
    }
    super.dispose();
  }

  void _maybeShowCoach() {
    if (!widget.appController.shouldShowCoachMarks) return;
    if (widget.itemsController.visibleItemsListenable.value.isEmpty && !_coachScheduled) {
      _coachScheduled = true;
      _coachListener = () {
        if (widget.itemsController.visibleItemsListenable.value.isNotEmpty) {
          widget.itemsController.visibleItemsListenable.removeListener(_coachListener!);
          _coachListener = null;
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCoach());
        }
      };
      widget.itemsController.visibleItemsListenable.addListener(_coachListener!);
      return;
    }
    _coachScheduled = false;
    final loc = AppLocalizations.of(context);
    _coachMark = TutorialCoachMark(
      targets: _buildTargets(loc),
      colorShadow: Colors.black.withOpacity(0.7),
      textSkip: loc.translate('skip'),
      onFinish: widget.appController.markCoachMarksSeen,
      onSkip: () => widget.appController.markCoachMarksSeen(),
    )..show(context: context);
  }

  List<TargetFocus> _buildTargets(AppLocalizations loc) {
    return [
      TargetFocus(
        identify: 'search',
        keyTarget: _searchKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(loc.translate('searchAnything'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      TargetFocus(
        identify: 'hero',
        keyTarget: _heroKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(loc.translate('rotateModel'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      TargetFocus(
        identify: 'card',
        keyTarget: _firstCardKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(loc.translate('tapCards'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      TargetFocus(
        identify: 'compare',
        keyTarget: _compareKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(loc.translate('compareHere'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(loc.translate('addItem'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: widget.appController.bottomNavNotifier,
        builder: (context, index, _) {
          return IndexedStack(
            index: index,
            children: _pages,
          );
        },
      ),
      bottomNavigationBar: AppBottomNav(
        appController: widget.appController,
        homeKey: null,
        catalogKey: null,
        compareKey: _compareKey,
        myItemsKey: null,
        settingsKey: null,
      ),
    );
  }
}
