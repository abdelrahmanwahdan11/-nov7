import 'package:flutter/material.dart';

import '../../data/models/variant.dart';

class VariantMatrixBuilder extends StatefulWidget {
  const VariantMatrixBuilder({
    super.key,
    required this.onGenerated,
  });

  final ValueChanged<List<Variant>> onGenerated;

  @override
  State<VariantMatrixBuilder> createState() => _VariantMatrixBuilderState();
}

class _VariantMatrixBuilderState extends State<VariantMatrixBuilder> {
  final Map<String, List<String>> _dimensions = <String, List<String>>{};
  final TextEditingController _dimensionController = TextEditingController();
  final TextEditingController _valuesController = TextEditingController();

  @override
  void dispose() {
    _dimensionController.dispose();
    _valuesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _dimensionController,
          decoration: const InputDecoration(labelText: 'Dimension (e.g. Color)'),
        ),
        TextField(
          controller: _valuesController,
          decoration: const InputDecoration(
            labelText: 'Values (comma separated, e.g. Blue,Green)',
          ),
          onSubmitted: (_) => _addDimension(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _dimensions.entries
              .map(
                (entry) => Chip(
                  label: Text('${entry.key}: ${entry.value.join('/')}' ),
                  onDeleted: () {
                    setState(() {
                      _dimensions.remove(entry.key);
                    });
                    _emitVariants();
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _addDimension,
          icon: const Icon(Icons.add),
          label: const Text('Add dimension'),
        ),
        const SizedBox(height: 16),
        Text(
          'Generated combinations: ${_calculateVariants().length}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  void _addDimension() {
    final name = _dimensionController.text.trim();
    final values = _valuesController.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (name.isEmpty || values.isEmpty) {
      return;
    }
    setState(() {
      _dimensions[name] = values;
    });
    _dimensionController.clear();
    _valuesController.clear();
    _emitVariants();
  }

  List<Variant> _calculateVariants() {
    if (_dimensions.isEmpty) {
      return const <Variant>[];
    }
    final keys = _dimensions.keys.toList();
    final List<Variant> variants = [];

    void buildVariant(int depth, Map<String, String> current) {
      if (depth == keys.length) {
        final id = current.values.join('-');
        variants.add(
          Variant(
            id: id,
            name: id,
            attrs: Map<String, String>.from(current),
            priceDelta: 0,
            images: const <String>[],
          ),
        );
        return;
      }
      final key = keys[depth];
      final values = _dimensions[key] ?? const <String>[];
      for (final value in values) {
        current[key] = value;
        buildVariant(depth + 1, current);
        current.remove(key);
      }
    }

    buildVariant(0, <String, String>{});
    return variants;
  }

  void _emitVariants() {
    final variants = _calculateVariants();
    widget.onGenerated(variants);
  }
}
