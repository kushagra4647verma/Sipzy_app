import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TrendingSection extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final Widget Function(Map<String, dynamic>) cardBuilder;

  const TrendingSection({
    super.key,
    required this.restaurants,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Trending Restaurants',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 280,
                child: cardBuilder(restaurants[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
