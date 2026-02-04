// lib/features/expert/widgets/expert_components.dart
// ✅ Reusable UI components for Expert features

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Helper class for safely accessing expert data with field name variations
class ExpertDataHelper {
  /// Safely get value from map with multiple possible keys
  static T safeGet<T>(
    Map<String, dynamic> map,
    List<String> keys,
    T defaultValue,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        if (value is T) return value;

        // Type conversion
        if (T == String) return value.toString() as T;
        if (T == int && value is num) return value.toInt() as T;
        if (T == double && value is num) return value.toDouble() as T;
      }
    }
    return defaultValue;
  }

  /// Get average rating from expert data
  static double getAvgRating(Map<String, dynamic> expert) {
    return safeGet<double>(
      expert,
      ['avg_score', 'avgRating', 'avg_rating'],
      0.0,
    );
  }

  /// Get total ratings count
  static int getTotalRatings(Map<String, dynamic> expert) {
    return safeGet<int>(
      expert,
      ['total_ratings', 'totalRatings'],
      0,
    );
  }

  /// Get years of experience
  static int getYearsExp(Map<String, dynamic> expert) {
    return safeGet<int>(
      expert,
      ['years_experience', 'yearsExp', 'yearsExperience'],
      0,
    );
  }

  /// Get expertise tags
  static List<String> getExpertiseTags(Map<String, dynamic> expert) {
    final tags = expert['expertise_tags'];
    if (tags is List) {
      return tags.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Calculate average from rating breakdown
  static double calculateRatingAverage(Map<String, dynamic> rating) {
    final presentation = rating['presentation_rating'] ?? 0;
    final taste = rating['taste_rating'] ?? 0;
    final ingredients = rating['ingredients_rating'] ?? 0;
    final accuracy = rating['accuracy_rating'] ?? 0;

    return (presentation + taste + ingredients + accuracy) / 4;
  }
}

/// Expert avatar with verified badge
class ExpertAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool showVerifiedBadge;

  const ExpertAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 32,
    this.showVerifiedBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.secondary,
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (showVerifiedBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(radius * 0.125),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.background,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.verified,
                color: Colors.white,
                size: radius * 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// Expert card for listing page
class ExpertCard extends StatelessWidget {
  final Map<String, dynamic> expert;
  final VoidCallback onTap;

  const ExpertCard({
    super.key,
    required this.expert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = expert['name'] ?? 'Expert';
    final city = expert['city'] ?? '';
    final category = expert['category'] ?? 'Sommelier';
    final profilePhoto = expert['profile_photo'];
    final avgRating = ExpertDataHelper.getAvgRating(expert);
    final totalRatings = ExpertDataHelper.getTotalRatings(expert);
    final yearsExp = ExpertDataHelper.getYearsExp(expert);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                ExpertAvatar(
                  photoUrl: profilePhoto,
                  name: name,
                  radius: 32,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Stats
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${avgRating.toStringAsFixed(1)} avg',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$totalRatings ratings',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      // Location & Experience
                      if (city.isNotEmpty || yearsExp > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (city.isNotEmpty) ...[
                              const Icon(
                                Icons.location_on,
                                color: AppTheme.textTertiary,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                city,
                                style: const TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (city.isNotEmpty && yearsExp > 0)
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            if (yearsExp > 0)
                              Text(
                                '$yearsExp yrs exp',
                                style: const TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rating breakdown row component
class RatingBreakdownRow extends StatelessWidget {
  final String label;
  final int rating;
  final int maxRating;

  const RatingBreakdownRow({
    super.key,
    required this.label,
    required this.rating,
    this.maxRating = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / maxRating,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          rating.toString(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Expert rating card for beverage ratings
class ExpertRatingCard extends StatelessWidget {
  final Map<String, dynamic> rating;

  const ExpertRatingCard({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final beverage = rating['beverages'] as Map<String, dynamic>? ?? {};
    final beverageName = beverage['name'] ?? 'Beverage';
    final beveragePhoto = beverage['photo'];
    final avgRating = ExpertDataHelper.calculateRatingAverage(rating);
    final createdAt = rating['created_at'] ?? '';
    final notes = rating['notes'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Beverage image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: beveragePhoto != null && beveragePhoto.toString().isNotEmpty
                ? Image.network(
                    beveragePhoto,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        beverageName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Rating breakdown
                RatingBreakdownRow(
                  label: 'Presentation',
                  rating: rating['presentation_rating'] ?? 0,
                ),
                const SizedBox(height: 8),
                RatingBreakdownRow(
                  label: 'Taste',
                  rating: rating['taste_rating'] ?? 0,
                ),
                const SizedBox(height: 8),
                RatingBreakdownRow(
                  label: 'Ingredients',
                  rating: rating['ingredients_rating'] ?? 0,
                ),
                const SizedBox(height: 8),
                RatingBreakdownRow(
                  label: 'Accuracy',
                  rating: rating['accuracy_rating'] ?? 0,
                ),

                // Notes
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 8),
                  Text(
                    notes.toString(),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.glassStrong,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.local_bar,
        color: AppTheme.textTertiary,
        size: 24,
      ),
    );
  }
}

/// Expertise tags display
class ExpertiseTags extends StatelessWidget {
  final List<String> tags;
  final int maxVisible;

  const ExpertiseTags({
    super.key,
    required this.tags,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final visibleTags = tags.take(maxVisible).toList();
    final hasMore = tags.length > maxVisible;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...visibleTags.map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondary.withOpacity(0.5),
              ),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '+${tags.length - maxVisible}',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Empty state for experts
class ExpertsEmptyState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ExpertsEmptyState({
    super.key,
    this.message = 'No experts found',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppTheme.gradientButtonPurple(
                onPressed: onAction!,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
