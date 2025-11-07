import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/items_controller.dart';

class SnapshotButton extends StatelessWidget {
  const SnapshotButton({
    super.key,
    required this.boundaryKey,
    required this.itemsController,
    required this.appController,
  });

  final GlobalKey boundaryKey;
  final ItemsController itemsController;
  final AppController appController;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(IconlyLight.image),
      tooltip: appController.reduceMotion ? 'Snapshot (static)' : 'Snapshot',
      onPressed: () async {
        final bytes = await itemsController.snapshotItem(boundaryKey);
        if (bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to capture snapshot')),
          );
          return;
        }
        await _copyToClipboard(bytes);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Snapshot copied to clipboard')),
        );
      },
    );
  }

  Future<void> _copyToClipboard(Uint8List bytes) async {
    final encoded = base64Encode(bytes);
    await Clipboard.setData(ClipboardData(text: encoded));
  }
}
