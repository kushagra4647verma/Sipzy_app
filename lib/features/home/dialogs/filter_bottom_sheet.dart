import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<String> selectedCuisines;
  final Set<String> selectedBaseDrinks;
  final Set<String> selectedRestaurantTypes;
  final double minRating;
  final double maxDistance;
  final double minCost;
  final double maxCost;
  final Function(Map<String, dynamic> filters) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedCuisines,
    required this.selectedBaseDrinks,
    required this.selectedRestaurantTypes,
    required this.minRating,
    required this.maxDistance,
    required this.minCost,
    required this.maxCost,
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

  final cuisines = [
    'Indian',
    'Continental',
    'Asian',
    'Mediterranean',
    'Italian',
    'Chinese'
  ];

  final baseDrinks = [
    'Whisky',
    'Rum',
    'Vodka',
    'Gin',
    'Beer',
    'Wine',
    'Water',
    'Soda',
    'Milk',
    'Juice'
  ];

  final restaurantTypes = [
    'Fine Dining',
    'Casual',
    'Romantic',
    'Gastropub',
    'Brewery'
  ];

  @override
  void initState() {
    super.initState();
    selectedCuisines = List.from(widget.selectedCuisines);
    selectedBaseDrinks = Set.from(widget.selectedBaseDrinks);
    selectedRestaurantTypes = Set.from(widget.selectedRestaurantTypes);
    minRating = widget.minRating;
    maxDistance = widget.maxDistance;
    minCost = widget.minCost;
    maxCost = widget.maxCost;
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

  void _applyFilters() {
    widget.onApply({
      'selectedCuisines': selectedCuisines,
      'selectedBaseDrinks': selectedBaseDrinks,
      'selectedRestaurantTypes': selectedRestaurantTypes,
      'minRating': minRating,
      'maxDistance': maxDistance,
      'minCost': minCost,
      'maxCost': maxCost,
    });
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
                // HEADER
                Row(
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
                ),

                const SizedBox(height: 24),

                // CUISINE
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
                  children: cuisines.map((cuisine) {
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

                const SizedBox(height: 24),

                // BASE DRINK
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
                  children: baseDrinks.map((drink) {
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

                const SizedBox(height: 24),

                // RATING
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
                  onChanged: (value) {
                    setState(() => minRating = value);
                  },
                ),

                const SizedBox(height: 16),

                // DISTANCE
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
                  onChanged: (value) {
                    setState(() => maxDistance = value);
                  },
                ),

                const SizedBox(height: 24),

                // RESTAURANT TYPE
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
                  children: restaurantTypes.map((type) {
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

                const SizedBox(height: 24),

                // COST FOR TWO
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

                const SizedBox(height: 32),

                // ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTheme.gradientButtonAmber(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
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
