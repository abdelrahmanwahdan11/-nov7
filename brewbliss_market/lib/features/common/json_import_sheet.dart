import 'package:flutter/material.dart';

import '../../controllers/items_controller.dart';

class JsonImportSheet extends StatefulWidget {
  const JsonImportSheet({
    super.key,
    required this.itemsController,
  });

  final ItemsController itemsController;

  @override
  State<JsonImportSheet> createState() => _JsonImportSheetState();
}

class _JsonImportSheetState extends State<JsonImportSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Paste JSON to import items.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final imported = await widget.itemsController.importItemsFromJson(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $imported items.')),
      );
      Navigator.of(context).pop(imported);
    } on FormatException catch (error) {
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      setState(() {
        _error = 'Unable to import data: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import JSON',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '[{ "id": "item_1", ... }]',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              errorText: _error,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleImport,
              icon: const Icon(Icons.upload_file_rounded),
              label: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Import'),
            ),
          ),
        ],
      ),
    );
  }
}
