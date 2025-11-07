import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/app_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/items_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_localizations.dart';
import 'features/auth/pages/forgot_page.dart';
import 'features/auth/pages/sign_in_page.dart';
import 'features/auth/pages/sign_up_page.dart';
import 'features/catalog/catalog_page.dart';
import 'features/compare/compare_page.dart';
import 'features/home/home_shell.dart';
import 'features/home/favorites_page.dart';
import 'features/item_detail/item_detail_page.dart';
import 'features/my_items/sell_item_form.dart';
import 'features/my_items/my_items_page.dart';
import 'features/offers/offers_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/search/search_page.dart';
import 'features/splash/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final appController = await AppController.init();
  final itemsController = await ItemsController.init();
  final authController = AuthController();
  runApp(BrewBlissApp(
    appController: appController,
    authController: authController,
    itemsController: itemsController,
  ));
}

class BrewBlissApp extends StatefulWidget {
  const BrewBlissApp({
    super.key,
    required this.appController,
    required this.authController,
    required this.itemsController,
  });

  final AppController appController;
  final AuthController authController;
  final ItemsController itemsController;

  @override
  State<BrewBlissApp> createState() => _BrewBlissAppState();
}

class _BrewBlissAppState extends State<BrewBlissApp> {
  late final GlobalKey<NavigatorState> _navigatorKey;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appController,
      builder: (context, _) {
        final locale = widget.appController.locale;
        final isRtl = locale.languageCode == 'ar';
        final theme = widget.appController.isDark
            ? AppTheme.dark(widget.appController.primaryColor)
            : AppTheme.light(widget.appController.primaryColor);
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'BrewBliss Market',
            theme: theme,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [AppLocalizationsDelegate()],
            initialRoute: '/splash',
            routes: {
              '/splash': (_) => SplashPage(
                    appController: widget.appController,
                  ),
              '/onboarding': (_) => OnboardingPage(
                    appController: widget.appController,
                  ),
              '/auth/signin': (_) => SignInPage(
                    authController: widget.authController,
                  ),
              '/auth/signup': (_) => SignUpPage(
                    authController: widget.authController,
                  ),
              '/auth/forgot': (_) => ForgotPage(
                    authController: widget.authController,
                  ),
              '/home': (_) => HomeShell(
                    appController: widget.appController,
                    itemsController: widget.itemsController,
                  ),
              '/catalog': (_) => CatalogPage(itemsController: widget.itemsController),
              '/compare': (_) => ComparePage(itemsController: widget.itemsController),
              '/search': (_) => SearchPage(itemsController: widget.itemsController),
              '/offers': (_) => OffersPage(itemsController: widget.itemsController),
              '/sell-item': (_) => SellItemFormPage(itemsController: widget.itemsController),
              '/favorites': (_) => FavoritesPage(itemsController: widget.itemsController),
              '/settings': (_) => SettingsPage(
                    appController: widget.appController,
                    itemsController: widget.itemsController,
                  ),
              '/my-items': (_) => MyItemsPage(
                    itemsController: widget.itemsController,
                  ),
            },
            onGenerateRoute: (settings) {
              if (settings.name != null && settings.name!.startsWith('/item/')) {
                final id = settings.name!.split('/').last;
                return MaterialPageRoute(
                  builder: (_) => ItemDetailPage(
                    itemId: id,
                    itemsController: widget.itemsController,
                  ),
                );
              }
              return null;
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.itemsController.dispose();
    widget.authController.dispose();
    widget.appController.dispose();
    super.dispose();
  }
}
