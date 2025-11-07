import 'package:flutter/material.dart';

import '../../controllers/items_controller.dart';
import '../../data/models/collection.dart';
import '../common/empty_state.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({
    super.key,
    required this.itemsController,
  });

  final ItemsController itemsController;

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCollection,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<List<Collection>>(
        valueListenable: widget.itemsController.collectionsListenable,
        builder: (context, collections, _) {
          if (collections.isEmpty) {
            return const EmptyState(
              title: 'No collections yet',
              message: 'Curate themed boards of your favorite finds.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemBuilder: (context, index) {
              final collection = collections[index];
              final items = widget.itemsController.itemsForCollection(collection.id);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: ExpansionTile(
                  title: Text(collection.name),
                  subtitle: Text('${items.length} items'),
                  children: [
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Nothing here yet. Add items from the catalog.'),
                      )
                    else
                      ...items.map(
                        (item) => ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.category),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => widget.itemsController
                                .toggleCollectionItem(collection.id, item.id),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => widget.itemsController
                            .deleteCollection(collection.id),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete collection'),
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: collections.length,
          );
        },
      ),
    );
  }

  Future<void> _createCollection() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create collection'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Collection name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      await widget.itemsController.createCollection(result);
    }
  }
}
