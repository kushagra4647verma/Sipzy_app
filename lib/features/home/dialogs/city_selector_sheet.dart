import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CitySelectorSheet extends StatelessWidget {
  final List<String> cities;
  final String selectedCity;
  final Function(String) onCitySelected;
  final VoidCallback onUseCurrentLocation;

  const CitySelectorSheet({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current Location Option
        ListTile(
          leading: const Icon(Icons.my_location, color: AppTheme.primary),
          title: const Text(
            'Use Current Location',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            onUseCurrentLocation();
          },
        ),
        const Divider(),

        // City List
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: cities.map((city) {
              final isSelected = city == selectedCity;

              return ListTile(
                title: Text(
                  city,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onCitySelected(city);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
