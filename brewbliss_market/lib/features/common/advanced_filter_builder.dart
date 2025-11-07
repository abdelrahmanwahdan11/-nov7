import 'package:flutter/material.dart';

class AdvancedFilterBuilder extends StatefulWidget {
  const AdvancedFilterBuilder({
    super.key,
    required this.onExpressionChanged,
  });

  final ValueChanged<String> onExpressionChanged;

  @override
  State<AdvancedFilterBuilder> createState() => _AdvancedFilterBuilderState();
}

class _AdvancedFilterBuilderState extends State<AdvancedFilterBuilder> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _presets = const <String>[
    'category=="Mugs" AND price<25',
    'allowOffers==true AND condition=="Like new"',
    '(tags~"vintage" OR tags~"artisan") AND price>=30',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Advanced filter expression',
            hintText: 'category=="Mugs" AND price<20',
          ),
          onChanged: widget.onExpressionChanged,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _presets
              .map(
                (preset) => ActionChip(
                  label: Text(preset),
                  onPressed: () {
                    _controller.text = preset;
                    widget.onExpressionChanged(preset);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
