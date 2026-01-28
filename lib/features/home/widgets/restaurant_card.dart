import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback onShareTap;
  final VoidCallback onCardTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.isBookmarked,
    required this.onBookmarkTap,
    required this.onShareTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = restaurant['logoImage'] ??
        restaurant['coverImage'] ??
        restaurant['image'];
    final name = restaurant['name'] ?? 'Restaurant';
    final area = restaurant['area'] ?? '';
    final distance = (restaurant['distance'] ?? 0).toDouble();
    final cuisines = (restaurant['cuisineTags'] as List?)?.take(2).toList() ??
        (restaurant['cuisine'] as List?)?.take(2).toList() ??
        [];
    final topDrink = restaurant['top_drink'] ?? '';
    final costForTwo = restaurant['cost_for_two'] ??
        restaurant['costForTwo'] ??
        (restaurant['priceRange'] ?? 0) * 500;
    final rating = restaurant['sipzy_rating'] ?? restaurant['rating'] ?? 4.0;

    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(image, name, area, distance),
            _buildDetailsSection(cuisines, topDrink, rating, costForTwo),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(
      String? image, String name, String area, double distance) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
          child: image != null && image.toString().isNotEmpty
              ? Image.network(
                  image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
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

        // Bookmark & Share buttons
        Positioned(
          top: 12,
          right: 12,
          child: Row(
            children: [
              _buildActionButton(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                onBookmarkTap,
                isBookmark: true,
              ),
              const SizedBox(width: 8),
              _buildActionButton(Icons.share_rounded, onShareTap),
            ],
          ),
        ),

        // Name + Location info
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
                      '$area • ${distance.toStringAsFixed(1)} km',
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
    );
  }

  Widget _buildDetailsSection(
      List cuisines, String topDrink, dynamic rating, dynamic costForTwo) {
    return Padding(
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
                        c.toString(),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      rating.toStringAsFixed(1),
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

  Widget _buildActionButton(IconData icon, VoidCallback onTap,
      {bool isBookmark = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isBookmark ? AppTheme.primary : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
