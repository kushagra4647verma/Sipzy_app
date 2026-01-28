import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final String selectedCity;
  final VoidCallback onCityTap;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final bool hasActiveFilters;
  final VoidCallback onFiltersTap;
  final VoidCallback onSortTap;
  final String sortLabel;
  final VoidCallback onExpertCornerTap;

  const HomeHeader({
    super.key,
    required this.selectedCity,
    required this.onCityTap,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.hasActiveFilters,
    required this.onFiltersTap,
    required this.onSortTap,
    required this.sortLabel,
    required this.onExpertCornerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Location and Expert Corner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLocationSelector(context),
              _buildExpertCornerButton(),
            ],
          ),

          const SizedBox(height: 16),

          // Search Bar
          _buildSearchBar(),

          const SizedBox(height: 12),

          // Filter & Sort Buttons
          _buildFilterSortButtons(context),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context) {
    return InkWell(
      onTap: onCityTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            selectedCity,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCornerButton() {
    return InkWell(
      onTap: onExpertCornerTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.secondary, AppTheme.secondaryLight],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Expert Corner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Search restaurants, cuisines, areas...',
          hintStyle: TextStyle(color: AppTheme.textTertiary),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          suffixIcon: Icon(
            Icons.mic_rounded,
            color: AppTheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSortButtons(BuildContext context) {
    return Row(
      children: [
        // Filters Button
        Expanded(
          child: InkWell(
            onTap: onFiltersTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.glassLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Sort Button
        Expanded(
          child: InkWell(
            onTap: onSortTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.glassLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      sortLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
