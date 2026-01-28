import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'restaurant_card.dart';

class FeaturedSection extends StatelessWidget {
  final List<Map<String, dynamic>> featuredRestaurants;
  final List<int> bookmarkedIds;
  final Function(String restaurantId) onBookmarkToggle;

  const FeaturedSection({
    super.key,
    required this.featuredRestaurants,
    required this.bookmarkedIds,
    required this.onBookmarkToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (featuredRestaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Spots',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featuredRestaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final restaurant = featuredRestaurants[index];
              final restaurantId = restaurant['id'] ?? 0;
              final isBookmarked = bookmarkedIds.contains(restaurantId);

              return SizedBox(
                width: 280,
                child: RestaurantCard(
                  restaurant: restaurant,
                  isBookmarked: isBookmarked,
                  onBookmarkToggle: onBookmarkToggle,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
