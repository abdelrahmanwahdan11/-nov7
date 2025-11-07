import 'package:flutter/material.dart';

import '../../controllers/items_controller.dart';
import '../../core/utils/app_localizations.dart';

Future<FilterOptions?> showFiltersSheet({
  required BuildContext context,
  required FilterOptions current,
  required List<String> categories,
  required List<String> conditions,
  required double minPrice,
  required double maxPrice,
}) {
  return showModalBottomSheet<FilterOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _FiltersSheet(
        current: current,
        categories: categories,
        conditions: conditions,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
    },
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.current,
    required this.categories,
    required this.conditions,
    required this.minPrice,
    required this.maxPrice,
  });

  final FilterOptions current;
  final List<String> categories;
  final List<String> conditions;
  final double minPrice;
  final double maxPrice;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late Set<String> _selectedCategories;
  late Set<String> _selectedConditions;
  late RangeValues _rangeValues;
  late bool _allowOffersOnly;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {...widget.current.categories};
    _selectedConditions = {...widget.current.conditions};
    final start = widget.current.minPrice ?? widget.minPrice;
    final end = widget.current.maxPrice ?? widget.maxPrice;
    final adjustedEnd = start == end ? start + 1 : end;
    _rangeValues = RangeValues(start, adjustedEnd);
    _allowOffersOnly = widget.current.allowOffersOnly;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(loc.translate('filters'), style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories.clear();
                      _selectedConditions.clear();
                      _rangeValues = RangeValues(widget.minPrice, widget.maxPrice == widget.minPrice ? widget.minPrice + 1 : widget.maxPrice);
                      _allowOffersOnly = false;
                    });
                  },
                  child: Text(loc.translate('clearFilters')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(loc.translate('category'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.remove(cat);
                      } else {
                        _selectedCategories.add(cat);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(loc.translate('condition'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.conditions.map((condition) {
                final selected = _selectedConditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedConditions.remove(condition);
                      } else {
                        _selectedConditions.add(condition);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(loc.translate('price'), style: Theme.of(context).textTheme.labelLarge),
            RangeSlider(
              values: _rangeValues,
              min: widget.minPrice,
              max: widget.maxPrice == widget.minPrice ? widget.minPrice + 1 : widget.maxPrice,
              divisions: 20,
              onChanged: (values) => setState(() => _rangeValues = values),
            ),
            Text('\$${_rangeValues.start.toStringAsFixed(0)} - \$${_rangeValues.end.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _allowOffersOnly,
              onChanged: (value) => setState(() => _allowOffersOnly = value),
              title: Text(loc.translate('keepOffers')),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    FilterOptions(
                      categories: _selectedCategories,
                      conditions: _selectedConditions,
                      minPrice: _rangeValues.start,
                      maxPrice: _rangeValues.end,
                      allowOffersOnly: _allowOffersOnly,
                    ),
                  );
                },
                child: Text(loc.translate('continueLabel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
