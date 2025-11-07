import 'package:flutter/material.dart';
import '../../controllers/items_controller.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/app_localizations.dart';
import '../../data/models/item.dart';

class SellItemFormPage extends StatefulWidget {
  const SellItemFormPage({super.key, required this.itemsController});

  final ItemsController itemsController;

  @override
  State<SellItemFormPage> createState() => _SellItemFormPageState();
}

class _SellItemFormPageState extends State<SellItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _conditionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagesController = TextEditingController();
  final _modelController = TextEditingController();
  bool _allowOffers = true;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _conditionController.dispose();
    _descriptionController.dispose();
    _imagesController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final images = _imagesController.text
        .split(',')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();
    if (images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provide at least one image URL')),
      );
      return;
    }
    final price = double.tryParse(_priceController.text);
    final item = Item(
      id: 'itm_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      brand: null,
      images: images,
      model3d: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
      price: price,
      attrs: {
        'Category': _categoryController.text.trim(),
        'Condition': _conditionController.text.trim(),
      },
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      condition: _conditionController.text.trim(),
      allowOffers: _allowOffers,
      ownerId: 'self',
      createdAt: DateTime.now(),
    );
    await widget.itemsController.addItem(item);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('sell')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.translate('name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty ? loc.translate('name') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: loc.translate('category'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? loc.translate('category')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.translate('price'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _allowOffers,
                onChanged: (value) => setState(() => _allowOffers = value),
                title: Text(loc.translate('allowOffers')),
              ),
              TextFormField(
                controller: _conditionController,
                decoration: InputDecoration(
                  labelText: loc.translate('condition'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? loc.translate('condition')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.translate('description'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? loc.translate('description')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imagesController,
                decoration: InputDecoration(
                  labelText: loc.translate('images'),
                  helperText: 'Comma separated network URLs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? loc.translate('images')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: loc.translate('model3d'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                child: Text(loc.translate('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
