import 'package:flutter/material.dart';
import '../../services/expert_service.dart';
import '../../core/theme/app_theme.dart';

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
      // UPDATED: Use new getExpertRatings method
      final ratings = await _expertService.getExpertRatings(
        widget.expertId,
        limit: 20, // Load more ratings
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

  // UPDATED: Enhanced data extraction with field variation handling
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
                  // NEW: Pull to refresh
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
      physics:
          const AlwaysScrollableScrollPhysics(), // NEW: For pull to refresh
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              _buildStatsSection(),
              _buildAboutSection(),
              _buildExpertiseSection(),
              _buildRatingsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  // UPDATED: Enhanced app bar with gradient
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.secondary.withOpacity(0.3),
                AppTheme.primary.withOpacity(0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: Enhanced profile header
  Widget _buildProfileHeader() {
    final name = expertDetails?['name'] ?? 'Expert';
    final category = expertDetails?['category'] ?? 'Sommelier';
    final city = expertDetails?['city'] ?? '';
    final avatar = expertDetails?['profile_photo'] ?? expertDetails?['avatar'];
    final verified =
        expertDetails?['verified'] ?? expertDetails?['status'] == 'approved';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // UPDATED: Avatar with verified badge and shadow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.3),
                      AppTheme.primary.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.secondary,
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
              if (verified)
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // UPDATED: Enhanced category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.3),
                  AppTheme.secondary.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (city.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  city,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // UPDATED: Enhanced stats section with better layout
  Widget _buildStatsSection() {
    final avgRating = _getAvgRating(expertDetails);
    final totalRatings = _getTotalRatings(expertDetails);
    final yearsExp = _getYearsExp(expertDetails);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.star_rounded,
              value: avgRating.toStringAsFixed(1),
              label: 'Avg Rating',
              color: AppTheme.primary,
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.border,
            ),
            _buildStatItem(
              icon: Icons.rate_review_rounded,
              value: totalRatings.toString(),
              label: 'Ratings',
              color: AppTheme.secondary,
            ),
            Container(
              width: 1,
              height: 40,
              color: AppTheme.border,
            ),
            _buildStatItem(
              icon: Icons.workspace_premium_rounded,
              value: yearsExp.toString(),
              label: 'Years Exp',
              color: AppTheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final bio = expertDetails?['bio'] ?? '';
    if (bio.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'About',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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

  // UPDATED: Enhanced expertise section
  Widget _buildExpertiseSection() {
    final expertise = expertDetails?['expertise'] as List?;
    if (expertise == null || expertise.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.local_bar_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expertise',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.secondary.withOpacity(0.3),
                      AppTheme.primary.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.secondary.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.secondary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.toString(),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // UPDATED: Enhanced ratings section
  Widget _buildRatingsSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.rate_review_rounded,
                  color: AppTheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Ratings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!ratingsLoading && expertRatings.isNotEmpty)
                Text(
                  '${expertRatings.length} total',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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

  // UPDATED: Enhanced rating card
  Widget _buildRatingCard(Map rating) {
    final beverageName = rating['beverage_name'] ?? 'Unknown Beverage';
    final beverageType = rating['beverage_type'] ?? '';
    final score = (rating['score'] ?? 0).toDouble();
    final comment = rating['comment'] ?? '';
    final date = rating['created_at'] ?? rating['date'] ?? '';

    // NEW: Extract rating breakdown scores
    final aroma = (rating['aroma_score'] ?? rating['aroma'] ?? 0).toDouble();
    final taste = (rating['taste_score'] ?? rating['taste'] ?? 0).toDouble();
    final finish = (rating['finish_score'] ?? rating['finish'] ?? 0).toDouble();
    final balance =
        (rating['balance_score'] ?? rating['balance'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beverageName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (beverageType.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        beverageType,
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Overall score badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.3),
                      AppTheme.secondary.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      score.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // NEW: Rating breakdown
          if (aroma > 0 || taste > 0 || finish > 0 || balance > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (aroma > 0) _buildMetricBadge('Aroma', aroma),
                if (taste > 0) _buildMetricBadge('Taste', taste),
                if (finish > 0) _buildMetricBadge('Finish', finish),
                if (balance > 0) _buildMetricBadge('Balance', balance),
              ],
            ),
          ],

          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.glassLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.border.withOpacity(0.5)),
              ),
              child: Text(
                comment,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],

          // Date
          if (date.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.textTertiary,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // NEW: Metric badge widget
  Widget _buildMetricBadge(String label, double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: AppTheme.secondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Format date helper
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else if (diff.inDays < 365) {
        final months = (diff.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (diff.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildRatingsError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
