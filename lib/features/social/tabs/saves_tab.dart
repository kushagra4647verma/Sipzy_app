import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/user_service.dart';
import '../../../core/theme/app_theme.dart';

class SavesTab extends StatelessWidget {
  final List bookmarks;
  final UserService userService;
  final VoidCallback onRefresh;
  final Function(String, {bool isError}) showToast;

  const SavesTab({
    super.key,
    required this.bookmarks,
    required this.userService,
    required this.onRefresh,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.primary,
      backgroundColor: AppTheme.card,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookmarks.length,
        itemBuilder: (_, i) => _BookmarkCard(
          bookmark: bookmarks[i],
          onRemove: (id, name) => _confirmRemoveBookmark(context, id, name),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child:
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          const Text(
            'No saved spots yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bookmark your favorite restaurants\nto easily find them later',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.explore, size: 20),
            label: const Text('Explore Restaurants'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBookmark(String restaurantId) async {
    try {
      final success = await userService.removeBookmark(restaurantId);

      if (success) {
        showToast('Bookmark removed');
        onRefresh();
      } else {
        showToast('Failed to remove bookmark', isError: true);
      }
    } catch (e) {
      print('❌ Remove bookmark error: $e');
      showToast('Error removing bookmark', isError: true);
    }
  }

  void _confirmRemoveBookmark(
      BuildContext context, String restaurantId, String name) {
    if (restaurantId.isEmpty) {
      showToast('Invalid restaurant ID', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text('Remove Bookmark?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "$name" from your saved restaurants?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeBookmark(restaurantId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Map bookmark;
  final Function(String, String) onRemove;

  const _BookmarkCard({
    required this.bookmark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Handle different API response formats
    final restaurantId = bookmark['restaurantId'] ??
        bookmark['restaurantid'] ??
        bookmark['restaurant_id'] ??
        bookmark['id'] ??
        '';

    final name = bookmark['name'] ??
        bookmark['restaurantName'] ??
        bookmark['restaurant_name'] ??
        'Restaurant';

    final area = bookmark['area'] ??
        bookmark['location'] ??
        bookmark['address'] ??
        bookmark['city'] ??
        '';

    final cuisines = bookmark['cuisine'] as List? ??
        bookmark['cuisines'] as List? ??
        bookmark['cuisineTags'] as List? ??
        [];

    final logoImage = bookmark['logoImage'] ??
        bookmark['logo_image'] ??
        bookmark['photo'] ??
        bookmark['image'] ??
        bookmark['coverImage'];

    final distance = bookmark['distance'];
    final rating = bookmark['rating'] ?? bookmark['sipzy_rating'];

    return GestureDetector(
      onTap: () {
        if (restaurantId.toString().isNotEmpty) {
          context.push('/restaurant/$restaurantId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border.withOpacity(0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            _buildThumbnail(logoImage),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark,
                            color: AppTheme.primary, size: 20),
                        onPressed: () =>
                            onRemove(restaurantId.toString(), name),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Location/Area
                  if (area.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppTheme.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            area,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${distance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Rating and Cuisine
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star,
                            color: AppTheme.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (cuisines.isNotEmpty)
                        Expanded(
                          child: Text(
                            cuisines.take(2).join(', '),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
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
            // Chevron
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(dynamic logoImage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: logoImage != null && logoImage.toString().isNotEmpty
          ? Image.network(
              logoImage.toString(),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholder();
              },
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.restaurant,
        color: AppTheme.textTertiary,
        size: 32,
      ),
    );
  }
}
