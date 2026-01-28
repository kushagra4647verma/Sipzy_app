import 'package:flutter/material.dart';
import '../../../services/location_service.dart';
import '../../../core/theme/app_theme.dart';

class CitySelectorSheet extends StatelessWidget {
  final String selectedCity;
  final List<String> cities;
  final Function(String city) onCitySelected;
  final Function(String message, {bool isError}) onToast;

  const CitySelectorSheet({
    super.key,
    required this.selectedCity,
    required this.cities,
    required this.onCitySelected,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    final locationService = LocationService();

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
          onTap: () async {
            Navigator.pop(context);

            final position =
                await locationService.getCurrentLocation(forceRefresh: true);

            if (context.mounted) {
              if (position != null && locationService.currentCity != null) {
                onCitySelected(locationService.currentCity!);
                onToast('Location updated to ${locationService.currentCity}');
              } else {
                onToast('Could not detect your city', isError: true);
              }
            }
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
                  locationService.setCity(city);
                  onCitySelected(city);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
