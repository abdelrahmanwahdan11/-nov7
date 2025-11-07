import 'package:flutter/material.dart';

class JsonImportSheet extends StatefulWidget {
  const JsonImportSheet({super.key, required this.onSubmit});

  final Future<void> Function(String raw) onSubmit;

  @override
  State<JsonImportSheet> createState() => _JsonImportSheetState();
}

class _JsonImportSheetState extends State<JsonImportSheet> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_controller.text);
      if (mounted) Navigator.of(context).pop();
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste JSON array of items',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: '[ { "id": "item-01" } ]',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_isSubmitting ? 'Importing...' : 'Import items'),
            ),
          ],
        ),
      ),
    );
  }
}
