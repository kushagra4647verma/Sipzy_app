import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/ui/share_modal.dart';

class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final bool isBookmarked;
  final Function(String restaurantId) onBookmarkToggle;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.isBookmarked,
    required this.onBookmarkToggle,
  });

  // Helper to safely get values from restaurant map
  T _safeGet<T>(Map<String, dynamic> map, String key, T defaultValue) {
    final value = map[key];
    if (value == null) return defaultValue;
    if (value is T) return value;

    // Type conversion attempts
    if (T == String) return value.toString() as T;
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is num) return value.toDouble() as T;

    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final restaurantId = _safeGet(restaurant, 'id', '').toString();
    final logoImage = restaurant['logo_image'] ?? restaurant['logoImage'];
    final coverImage = restaurant['cover_image'] ?? restaurant['coverImage'];
    final image = logoImage ?? coverImage;

    final name = _safeGet(restaurant, 'name', 'Restaurant');
    final area = _safeGet(restaurant, 'area', '');
    final distance = _safeGet<num>(restaurant, 'distance', 0).toDouble();
    final cuisineTags = restaurant['cuisine_tags'] ?? restaurant['cuisineTags'];

    List<String> cuisines = [];
    if (cuisineTags is List && cuisineTags.isNotEmpty) {
      cuisines = cuisineTags.take(2).map((e) => e.toString()).toList();
    }
    final topDrink = _safeGet(restaurant, 'top_drink', '');
    final priceRange =
        restaurant['price_range'] ?? restaurant['priceRange'] ?? 2;
    final costForTwo = (priceRange * 500);

    final rating = _safeGet<num>(restaurant, 'sipzy_rating', 0).toDouble();
    final displayRating = rating > 0 ? rating : 4.0;
    return GestureDetector(
      onTap: () {
        print('🔍 Card tapped! ID: $restaurantId');
        context.push('/restaurant/$restaurantId');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE + ACTIONS
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: image != null && image.isNotEmpty
                      ? Image.network(
                          image,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),

                // Gradient overlay
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),

                // Bookmark & Share
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onBookmarkToggle(restaurantId.toString()),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => ShareModal(
                              onClose: () => Navigator.pop(context),
                              item: {
                                'title': name,
                                'description': 'Check out this restaurant!',
                                'url':
                                    'https://sipzy.co.in/restaurant/$restaurantId',
                              },
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Name + Location
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              area.isNotEmpty
                                  ? '$area • ${distance.toStringAsFixed(1)} km'
                                  : '${distance.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // DETAILS
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cuisines
                  if (cuisines.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: cuisines
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                  // Top Drink
                  if (topDrink.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_bar,
                          color: AppTheme.secondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            topDrink,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Rating & Cost
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              displayRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₹$costForTwo for 2',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }
}
