import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/app_controller.dart';
import '../../core/utils/app_localizations.dart';

class ExperimentsPage extends StatelessWidget {
  const ExperimentsPage({super.key, required this.appController});

  final AppController appController;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(loc.translate('experiments')),
            actions: const [Icon(IconlyLight.discovery)],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ExperimentSwitchTile(
                title: loc.translate('reduceMotion'),
                description: 'Turn off secondary animations for sensitive users.',
                value: appController.reduceMotion,
                onChanged: (value) => appController.setFeatureFlag('reduceMotion', value),
              ),
              _ExperimentSwitchTile(
                title: 'Enable particles',
                description: 'Prototype coffee steam particle effects.',
                value: appController.enableParticles,
                onChanged: (value) => appController.setFeatureFlag('enableParticles', value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExperimentSwitchTile extends StatelessWidget {
  const _ExperimentSwitchTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
