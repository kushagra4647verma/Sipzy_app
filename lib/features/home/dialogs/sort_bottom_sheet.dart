import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final Function(String sortBy) onSortSelected;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  String _getSortLabel(String value) {
    switch (value) {
      case 'rating':
        return 'Highest Rating';
      case 'distance':
        return 'Nearest First';
      case 'cost_low':
        return 'Cost: Low to High';
      case 'cost_high':
        return 'Cost: High to Low';
      default:
        return 'Highest Rating';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sort By',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSortOption(context, 'Highest Rating', 'rating'),
          _buildSortOption(context, 'Nearest First', 'distance'),
          _buildSortOption(context, 'Cost Low to High', 'cost_low'),
          _buildSortOption(context, 'Cost High to Low', 'cost_high'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String label, String value) {
    final isSelected = currentSort == value;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () {
        onSortSelected(value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
