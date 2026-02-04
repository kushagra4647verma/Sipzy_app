import 'package:flutter/material.dart';
import '../../services/expert_service.dart';
import '../expert/expert_profile_detail_page.dart';
import '../../core/theme/app_theme.dart';

class ExpertCornerPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ExpertCornerPage({super.key, required this.user});

  @override
  State<ExpertCornerPage> createState() => _ExpertCornerPageState();
}

class _ExpertCornerPageState extends State<ExpertCornerPage> {
  final _expertService = ExpertService();

  List experts = [];
  List filteredExperts = [];
  bool loading = true;
  bool hasError = false;
  String searchQuery = '';
  String? selectedCity; // NEW: City filter support

  @override
  void initState() {
    super.initState();
    fetchExperts();
  }

  Future<void> fetchExperts() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      // UPDATED: Pass city filter to service
      final fetchedExperts = await _expertService.getExperts(
        city: selectedCity,
      );

      if (mounted) {
        setState(() {
          experts = fetchedExperts;
          filteredExperts = experts;
          hasError = false;
        });
      }
    } catch (e) {
      print('❌ Fetch experts error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load experts', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _filterExperts(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredExperts = experts;
      } else {
        filteredExperts = experts.where((expert) {
          final name = (expert['name'] ?? '').toString().toLowerCase();
          final category = (expert['category'] ?? '').toString().toLowerCase();
          final city = (expert['city'] ?? '').toString().toLowerCase();
          final queryLower = query.toLowerCase();
          return name.contains(queryLower) ||
              category.contains(queryLower) ||
              city.contains(queryLower);
        }).toList();
      }
    });
  }

  // UPDATED: Enhanced data extraction with field variation handling
  double _getAvgRating(Map expert) {
    final value =
        expert['avg_score'] ?? expert['avgRating'] ?? expert['avg_rating'] ?? 0;
    return value is num ? value.toDouble() : 0.0;
  }

  int _getTotalRatings(Map expert) {
    final value = expert['total_ratings'] ?? expert['totalRatings'] ?? 0;
    return value is int ? value : (value is num ? value.toInt() : 0);
  }

  int _getYearsExp(Map expert) {
    final value = expert['years_experience'] ??
        expert['yearsExp'] ??
        expert['yearsExperience'] ??
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildExpertsCount(),
            Expanded(
              child: loading
                  ? _buildLoading()
                  : hasError
                      ? _buildError()
                      : RefreshIndicator(
                          // NEW: Pull to refresh
                          onRefresh: fetchExperts,
                          color: AppTheme.primary,
                          backgroundColor: AppTheme.card,
                          child: _buildExpertsList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          // UPDATED: Enhanced header with verified badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.secondary, AppTheme.secondaryLight],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Expert Corner',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: TextField(
          onChanged: _filterExperts,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search experts by name, specialty, or city...',
            hintStyle: TextStyle(color: AppTheme.textTertiary),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpertsCount() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // UPDATED: Enhanced count display with icon
          const Icon(
            Icons.verified_user,
            size: 16,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            '${filteredExperts.length} Verified Beverage Expert${filteredExperts.length != 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertsList() {
    if (filteredExperts.isEmpty) {
      return _buildEmptyState(); // UPDATED: Enhanced empty state
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics:
          const AlwaysScrollableScrollPhysics(), // NEW: For pull to refresh
      itemCount: filteredExperts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildExpertCard(filteredExperts[index]);
      },
    );
  }

  // UPDATED: Completely redesigned expert card
  Widget _buildExpertCard(Map expert) {
    final name = expert['name'] ?? 'Expert';
    final category = expert['category'] ?? 'Sommelier';
    final city = expert['city'] ?? '';
    final avatar = expert['profile_photo'] ?? expert['avatar'];
    final avgRating = _getAvgRating(expert);
    final totalRatings = _getTotalRatings(expert);
    final yearsExp = _getYearsExp(expert);
    final verified = expert['verified'] ?? expert['status'] == 'approved';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        // NEW: Subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpertProfileDetailPage(
                user: widget.user,
                expertId: expert['user_id']?.toString() ??
                    expert['id']?.toString() ??
                    '',
              ),
            ),
          );
        },
        child: Row(
          children: [
            // UPDATED: Avatar with verified badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (verified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppTheme.background, width: 2),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Expert info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // UPDATED: Enhanced category badge
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
                  // UPDATED: Enhanced stats row
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
                  // NEW: Location and experience row
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

            // Arrow button
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpertProfileDetailPage(
                      user: widget.user,
                      expertId: expert['user_id']?.toString() ??
                          expert['id']?.toString() ??
                          '',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textTertiary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }

  // UPDATED: Enhanced error state
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
                Icons.cloud_off_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load experts',
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
              onPressed: fetchExperts,
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

  // UPDATED: Enhanced empty state with better messaging
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              'No experts found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Check back later for expert recommendations',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              AppTheme.gradientButtonPurple(
                onPressed: () {
                  setState(() {
                    searchQuery = '';
                    filteredExperts = experts;
                  });
                },
                child: const Text(
                  'Clear Search',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
