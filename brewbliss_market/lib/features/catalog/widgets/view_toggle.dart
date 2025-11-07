import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

enum CatalogViewMode { grid, list }

class ViewToggle extends StatelessWidget {
  const ViewToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final CatalogViewMode mode;
  final ValueChanged<CatalogViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            context,
            icon: IconlyBold.category,
            isActive: mode == CatalogViewMode.grid,
            onTap: () => onChanged(CatalogViewMode.grid),
          ),
          _buildButton(
            context,
            icon: IconlyBold.paper,
            isActive: mode == CatalogViewMode.list,
            onTap: () => onChanged(CatalogViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required IconData icon, required bool isActive, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          icon,
          color: isActive ? colorScheme.onPrimary : colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
