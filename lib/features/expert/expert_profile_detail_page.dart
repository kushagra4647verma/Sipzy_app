import 'package:flutter/material.dart';
import '../../services/expert_service.dart';
import '../../core/theme/app_theme.dart';

/// Expert Profile Detail Page - Redesigned to match exact UI
/// Features:
/// - Purple gradient header with avatar
/// - Quick stats cards (Total Ratings, Avg Score, Years Exp)
/// - About section
/// - Specializations tags
/// - Recent expert ratings list with beverage thumbnails
class ExpertProfileDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String expertId;

  const ExpertProfileDetailPage({
    super.key,
    required this.user,
    required this.expertId,
  });

  @override
  State<ExpertProfileDetailPage> createState() =>
      _ExpertProfileDetailPageState();
}

class _ExpertProfileDetailPageState extends State<ExpertProfileDetailPage> {
  final _expertService = ExpertService();

  Map<String, dynamic>? expertDetails;
  List expertRatings = [];
  bool loading = true;
  bool ratingsLoading = true;
  bool hasError = false;
  bool ratingsError = false;

  @override
  void initState() {
    super.initState();
    _loadExpertData();
  }

  Future<void> _loadExpertData() async {
    await Future.wait([
      _fetchExpertDetails(),
      _fetchExpertRatings(),
    ]);
  }

  Future<void> _fetchExpertDetails() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final details = await _expertService.getExpert(widget.expertId);

      if (mounted) {
        setState(() {
          expertDetails = details;
          hasError = false;
        });
      }
    } catch (e) {
      print('❌ Fetch expert details error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load expert details', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _fetchExpertRatings() async {
    setState(() {
      ratingsLoading = true;
      ratingsError = false;
    });

    try {
      final ratings = await _expertService.getExpertRatings(
        widget.expertId,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          expertRatings = ratings;
          ratingsError = false;
        });
      }
    } catch (e) {
      print('❌ Fetch expert ratings error: $e');
      if (mounted) {
        setState(() => ratingsError = true);
      }
    } finally {
      if (mounted) {
        setState(() => ratingsLoading = false);
      }
    }
  }

  double _getAvgRating(Map? data) {
    if (data == null) return 0.0;
    final value =
        data['avg_score'] ?? data['avgRating'] ?? data['avg_rating'] ?? 0;
    return value is num ? value.toDouble() : 0.0;
  }

  int _getTotalRatings(Map? data) {
    if (data == null) return 0;
    final value = data['total_ratings'] ?? data['totalRatings'] ?? 0;
    return value is int ? value : (value is num ? value.toInt() : 0);
  }

  int _getYearsExp(Map? data) {
    if (data == null) return 0;
    final value = data['years_experience'] ??
        data['yearsExp'] ??
        data['yearsExperience'] ??
        0;
    return value is int ? value : (value is num ? value.toInt() : 0);
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: loading
          ? _buildLoading()
          : hasError
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadExpertData,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.card,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    if (expertDetails == null) {
      return const Center(child: Text('Expert not found'));
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Purple gradient header with avatar
        _buildGradientHeader(),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Quick Stats Section
              _buildQuickStats(),

              const SizedBox(height: 24),

              // About the Expert
              _buildAboutSection(),

              const SizedBox(height: 24),

              // Specializations
              _buildSpecializationsSection(),

              const SizedBox(height: 24),

              // Recent Expert Ratings
              _buildRecentRatingsSection(),

              const SizedBox(height: 80), // Bottom padding for navigation
            ],
          ),
        ),
      ],
    );
  }

  /// Purple gradient header with back button, avatar, and expert info
  Widget _buildGradientHeader() {
    final name = expertDetails?['name'] ?? 'Expert';
    final category = expertDetails?['category'] ?? 'Sommelier';
    final avatar = expertDetails?['profile_photo'] ?? expertDetails?['avatar'];
    final verified =
        expertDetails?['verified'] ?? expertDetails?['status'] == 'approved';

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppTheme.background,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                const Text(
                  'SipZy Expert',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Purple gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.secondary,
                    AppTheme.secondary.withOpacity(0.7),
                    AppTheme.primary.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 320,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      // Avatar with verified badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),

                          // Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage:
                                  avatar != null && avatar.toString().isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                              child: avatar == null || avatar.toString().isEmpty
                                  ? Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          // Verified badge
                          if (verified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppTheme.secondary.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Name with "Updated" status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Verified Expert badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Verified Expert',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Category badge (Sommelier)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.wine_bar,
                              color: Colors.black,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick Stats Section - 3 cards
  Widget _buildQuickStats() {
    final totalRatings = _getTotalRatings(expertDetails);
    final avgRating = _getAvgRating(expertDetails);
    final yearsExp = _getYearsExp(expertDetails);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Stats',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats cards row
          Row(
            children: [
              // Total Ratings
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.primary,
                  value: totalRatings.toString(),
                  label: 'Total Ratings',
                ),
              ),

              const SizedBox(width: 12),

              // Avg Score
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  iconColor: AppTheme.secondary,
                  value: avgRating.toStringAsFixed(1),
                  label: 'Avg Score',
                ),
              ),

              const SizedBox(width: 12),

              // Years Exp
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  iconColor: Colors.green,
                  value: yearsExp.toString(),
                  label: 'Years Exp',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// About the Expert section
  Widget _buildAboutSection() {
    final bio = expertDetails?['bio'] ??
        'Expert sommelier with 15+ years of experience in beverage tasting and evaluation.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'About the Expert',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bio text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              bio,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Specializations section with purple tags
  Widget _buildSpecializationsSection() {
    // Default specializations if none provided
    final expertise = expertDetails?['expertise'] as List? ??
        ['Cocktails', 'Wine', 'Whiskey', 'Craft Beer', 'Mocktails'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.local_bar,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Specializations',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: expertise.map<Widget>((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.secondary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  item.toString(),
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Recent Expert Ratings section
  Widget _buildRecentRatingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recent Expert Ratings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Ratings list
          if (ratingsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (ratingsError)
            _buildRatingsError()
          else if (expertRatings.isEmpty)
            _buildNoRatings()
          else
            ...expertRatings.map((rating) => _buildRatingCard(rating)),
        ],
      ),
    );
  }

  /// Individual rating card with beverage thumbnail
  Widget _buildRatingCard(Map rating) {
    final beverageName = rating['beverage_name'] ??
        rating['beverages']?['name'] ??
        'Unknown Beverage';
    final beveragePhoto =
        rating['beverage_photo'] ?? rating['beverages']?['photo'];
    final score = (rating['score'] ??
            rating['avgRating'] ??
            _calculateAverageRating(rating))
        .toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Beverage thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: beveragePhoto != null && beveragePhoto.toString().isNotEmpty
                ? Image.network(
                    beveragePhoto,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
                  )
                : _buildPhotoPlaceholder(),
          ),

          const SizedBox(width: 12),

          // Beverage name
          Expanded(
            child: Text(
              beverageName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 12),

          // Rating
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppTheme.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: 50,
      height: 50,
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

  double _calculateAverageRating(Map rating) {
    final presentation = rating['presentation_rating'] ?? 0;
    final taste = rating['taste_rating'] ?? 0;
    final ingredients = rating['ingredients_rating'] ?? 0;
    final accuracy = rating['accuracy_rating'] ?? 0;

    if (presentation == 0 && taste == 0 && ingredients == 0 && accuracy == 0) {
      return 0;
    }

    return (presentation + taste + ingredients + accuracy) / 4;
  }

  Widget _buildRatingsError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.textTertiary,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Failed to load ratings',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          AppTheme.gradientButtonPurple(
            onPressed: _fetchExpertRatings,
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRatings() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondary.withOpacity(0.2),
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: AppTheme.textTertiary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No ratings yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This expert hasn\'t received any ratings',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  Widget _buildError() {
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
                    Colors.red.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load expert profile',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppTheme.gradientButtonPurple(
              onPressed: _loadExpertData,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Retry', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
