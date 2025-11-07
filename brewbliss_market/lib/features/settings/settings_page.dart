import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/items_controller.dart';
import '../../core/utils/app_localizations.dart';
import '../../widgets/color_picker_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.appController,
    required this.itemsController,
  });

  final AppController appController;
  final ItemsController itemsController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = appController.isDark;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            value: isDark,
            onChanged: (_) => appController.toggleTheme(),
            title: Text(loc.translate('darkMode')),
          ),
          ListTile(
            leading: const Icon(IconlyBold.filter_2),
            title: Text(loc.translate('language')),
            trailing: DropdownButton<String>(
              value: appController.locale.languageCode,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(loc.translate('languageEnglish')),
                ),
                DropdownMenuItem(
                  value: 'ar',
                  child: Text(loc.translate('languageArabic')),
                ),
              ],
              onChanged: (value) {
                if (value != null) appController.setLocale(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(IconlyBold.edit),
            title: Text(loc.translate('primaryColor')),
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (_) => ColorPickerSheet(
                onColorSelected: (color) => appController.setPrimary(color),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(IconlyBold.show),
            title: Text(loc.translate('tutorialReplay')),
            onTap: () {
              appController.resetCoachMarks();
              Navigator.of(context).pushNamed('/onboarding');
            },
          ),
          ListTile(
            leading: const Icon(IconlyBold.delete),
            title: Text(loc.translate('clearStorage')),
            onTap: () async {
              await appController.clearStorage();
              await itemsController.clearLocalData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('clearStorage'))),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
