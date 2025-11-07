import 'package:flutter/material.dart';

import '../../controllers/items_controller.dart';
import '../../data/models/collection.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createCollection() async {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    final collection = Collection(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      name: text,
    );
    await widget.itemsController.upsertCollection(collection);
    _nameController.clear();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_outlined),
            onPressed: _createCollection,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Collection>>(
        valueListenable: widget.itemsController.collectionsListenable,
        builder: (context, collections, _) {
          if (collections.isEmpty) {
            return Center(
              child: Text(
                'No collections yet',
                style: theme.textTheme.titleMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ListTile(
                  title: Text(collection.name),
                  subtitle: Text('${collection.itemIds.length} items'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => widget.itemsController
                        .removeCollection(collection.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Collection name',
            suffixIcon: IconButton(
              icon: const Icon(Icons.check),
              onPressed: _createCollection,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _createCollection(),
        ),
      ),
    );
  }
}
