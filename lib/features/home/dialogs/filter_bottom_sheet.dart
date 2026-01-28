import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FilterData {
  final List<String> selectedCuisines;
  final Set<String> selectedBaseDrinks;
  final Set<String> selectedRestaurantTypes;
  final double minRating;
  final double maxDistance;
  final double minCost;
  final double maxCost;

  FilterData({
    required this.selectedCuisines,
    required this.selectedBaseDrinks,
    required this.selectedRestaurantTypes,
    required this.minRating,
    required this.maxDistance,
    required this.minCost,
    required this.maxCost,
  });

  FilterData copyWith({
    List<String>? selectedCuisines,
    Set<String>? selectedBaseDrinks,
    Set<String>? selectedRestaurantTypes,
    double? minRating,
    double? maxDistance,
    double? minCost,
    double? maxCost,
  }) {
    return FilterData(
      selectedCuisines: selectedCuisines ?? this.selectedCuisines,
      selectedBaseDrinks: selectedBaseDrinks ?? this.selectedBaseDrinks,
      selectedRestaurantTypes:
          selectedRestaurantTypes ?? this.selectedRestaurantTypes,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      minCost: minCost ?? this.minCost,
      maxCost: maxCost ?? this.maxCost,
    );
  }
}

class FilterBottomSheet extends StatefulWidget {
  final List<String> cuisines;
  final List<String> baseDrinks;
  final List<String> restaurantTypes;
  final FilterData initialFilters;
  final Function(FilterData) onApply;

  const FilterBottomSheet({
    super.key,
    required this.cuisines,
    required this.baseDrinks,
    required this.restaurantTypes,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> selectedCuisines;
  late Set<String> selectedBaseDrinks;
  late Set<String> selectedRestaurantTypes;
  late double minRating;
  late double maxDistance;
  late double minCost;
  late double maxCost;

  @override
  void initState() {
    super.initState();
    selectedCuisines = List.from(widget.initialFilters.selectedCuisines);
    selectedBaseDrinks = Set.from(widget.initialFilters.selectedBaseDrinks);
    selectedRestaurantTypes =
        Set.from(widget.initialFilters.selectedRestaurantTypes);
    minRating = widget.initialFilters.minRating;
    maxDistance = widget.initialFilters.maxDistance;
    minCost = widget.initialFilters.minCost;
    maxCost = widget.initialFilters.maxCost;
  }

  void _clearAll() {
    setState(() {
      selectedCuisines.clear();
      selectedBaseDrinks.clear();
      selectedRestaurantTypes.clear();
      minRating = 0;
      maxDistance = 10;
      minCost = 0;
      maxCost = 5000;
    });
  }

  void _apply() {
    widget.onApply(FilterData(
      selectedCuisines: selectedCuisines,
      selectedBaseDrinks: selectedBaseDrinks,
      selectedRestaurantTypes: selectedRestaurantTypes,
      minRating: minRating,
      maxDistance: maxDistance,
      minCost: minCost,
      maxCost: maxCost,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCuisineSection(),
                const SizedBox(height: 24),
                _buildBaseDrinkSection(),
                const SizedBox(height: 24),
                _buildRatingSection(),
                const SizedBox(height: 16),
                _buildDistanceSection(),
                const SizedBox(height: 24),
                _buildRestaurantTypeSection(),
                const SizedBox(height: 24),
                _buildCostSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Filters',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.close,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildCuisineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cuisine',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.cuisines.map((cuisine) {
            final isSelected = selectedCuisines.contains(cuisine);
            return _filterChip(
              label: cuisine,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedCuisines.remove(cuisine);
                  } else {
                    selectedCuisines.clear();
                    selectedCuisines.add(cuisine);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBaseDrinkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Base Drink',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.baseDrinks.map((drink) {
            final isSelected = selectedBaseDrinks.contains(drink);
            return _filterChip(
              label: drink,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedBaseDrinks.remove(drink);
                  } else {
                    selectedBaseDrinks.add(drink);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SipZy Rating: ${minRating.toStringAsFixed(1)}+ stars',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.border,
          onChanged: (value) => setState(() => minRating = value),
        ),
      ],
    );
  }

  Widget _buildDistanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distance: Up to ${maxDistance.toStringAsFixed(1)} km',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Slider(
          value: maxDistance,
          min: 0,
          max: 10,
          divisions: 20,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.border,
          onChanged: (value) => setState(() => maxDistance = value),
        ),
      ],
    );
  }

  Widget _buildRestaurantTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Restaurant Type',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.restaurantTypes.map((type) {
            final isSelected = selectedRestaurantTypes.contains(type);
            return _filterChip(
              label: type,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedRestaurantTypes.remove(type);
                  } else {
                    selectedRestaurantTypes.add(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCostSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost for Two: ₹${minCost.toInt()} - ₹${maxCost.toInt()}',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: RangeValues(minCost, maxCost),
          min: 0,
          max: 5000,
          divisions: 50,
          activeColor: AppTheme.primary,
          inactiveColor: AppTheme.border,
          onChanged: (values) {
            setState(() {
              minCost = values.start;
              maxCost = values.end;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearAll,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTheme.gradientButtonAmber(
            onPressed: _apply,
            child: const Text('Apply Filters'),
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                )
              : null,
          color: isSelected ? null : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
