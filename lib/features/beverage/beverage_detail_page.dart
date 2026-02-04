import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/ui/share_modal.dart';
import '../../core/theme/app_theme.dart';
import '../../services/beverage_service.dart';
import '../../services/camera_service.dart';

class BeverageDetailPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String beverageId;

  const BeverageDetailPage({
    super.key,
    required this.user,
    required this.beverageId,
  });

  @override
  State<BeverageDetailPage> createState() => _BeverageDetailPageState();
}

class _BeverageDetailPageState extends State<BeverageDetailPage> {
  final _beverageService = BeverageService();

  Map<String, dynamic>? beverage;
  bool loading = true;
  bool hasError = false;

  bool showRatingDialog = false;
  bool showReviewsDialog = false;
  bool showExpertBreakdown = false;
  List<String> _userUploadedPhotos = [];

  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchBeverage();
  }

  Future<void> fetchBeverage() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final result = await _beverageService.getBeverage(widget.beverageId);

      if (mounted && result != null) {
        setState(() {
          beverage = result;
          hasError = false;
        });
        if (mounted && beverage != null) {
          final userPhotos = await _fetchUserUploadedBeveragePhotos();
          if (mounted) {
            setState(() {
              _userUploadedPhotos = userPhotos;
            });
          }
        }
      } else {
        throw Exception('Beverage not found');
      }
    } catch (e) {
      print('❌ Fetch beverage error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load beverage details', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> submitRating(int selectedRating, String reviewText) async {
    if (selectedRating == 0) {
      _toast('Please select a rating', isError: true);
      return;
    }

    setState(() => submitting = true);

    try {
      // ✅ FIXED: Updated to match service signature
      final success = await _beverageService.rateBeverage(
        widget.beverageId,
        selectedRating,
        comments: reviewText.isNotEmpty ? reviewText : null,
      );

      if (success) {
        _toast('Rating submitted!');
        // Refresh beverage data to show updated ratings
        await fetchBeverage();
      } else {
        _toast('Failed to submit rating', isError: true);
      }
    } catch (e) {
      print('❌ Submit rating error: $e');
      _toast('Failed to submit rating', isError: true);
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  Future<List<String>> _fetchUserUploadedBeveragePhotos() async {
    try {
      final supabase = Supabase.instance.client;

      // List all files in the user-uploads folder
      final result = await supabase.storage
          .from('beverage-photos')
          .list(path: 'user-uploads');

      if (result.isEmpty) return [];

      // Get beverage ID from current beverage
      final currentBeverageId = widget.beverageId;

      // Filter photos that belong to this beverage
      final photos = <String>[];
      for (final file in result) {
        final fileName = file.name;

        // Check if this photo belongs to current beverage
        // Format: {beverageId}_{timestamp}.jpg
        final beverageId = fileName.split('_').first;

        if (beverageId == currentBeverageId) {
          final photoUrl = supabase.storage
              .from('beverage-photos')
              .getPublicUrl('user-uploads/$fileName');
          photos.add(photoUrl);
        }
      }

      print('📸 Found ${photos.length} user-uploaded photos for this beverage');
      return photos;
    } catch (e) {
      print('❌ Error fetching user-uploaded photos: $e');
      return [];
    }
  }

  void _showRatingDialog() {
    int selectedRating = 0;
    String reviewText = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.card,
          title: Text(
            'Rate ${beverage?['name'] ?? 'Beverage'}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your Rating',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => reviewText = v,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  filled: true,
                  fillColor: AppTheme.glassLight,
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () {
                      if (selectedRating > 0) {
                        Navigator.pop(context);
                        submitRating(selectedRating, reviewText);
                      } else {
                        _toast('Please select a rating', isError: true);
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Text('Submit Rating',
                      style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpertRatings() async {
    // Fetch expert ratings from API
    final ratingsData = await _beverageService.getExpertRatings(
      widget.beverageId,
      page: 1,
      limit: 20,
    );

    if (!mounted) return;

    // Extract ratings array from response
    final expertRatings = ratingsData?['ratings'] as List? ?? [];
    final pagination =
        ratingsData?['pagination'] as Map<String, dynamic>? ?? {};

    if (expertRatings.isEmpty) {
      _toast('No expert ratings yet');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.secondary,
                              AppTheme.secondaryLight
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Expert Ratings (${pagination['total'] ?? expertRatings.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 500,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: expertRatings.length,
                itemBuilder: (context, index) {
                  final rating = expertRatings[index];
                  final expert =
                      rating['expert'] as Map<String, dynamic>? ?? {};

                  // Calculate average rating
                  final avgRating = ((rating['presentation_rating'] ?? 0) +
                          (rating['taste_rating'] ?? 0) +
                          (rating['ingredients_rating'] ?? 0) +
                          (rating['accuracy_rating'] ?? 0)) /
                      4;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expert Header
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.secondary,
                                  backgroundImage: expert['profile_photo'] !=
                                          null
                                      ? NetworkImage(expert['profile_photo'])
                                      : null,
                                  child: expert['profile_photo'] == null
                                      ? Text(
                                          (expert['name'] ?? 'E')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.card,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expert['name'] ?? 'Expert',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Expertise tags
                                  if (expert['expertise_tags'] != null)
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: (expert['expertise_tags']
                                              as List)
                                          .take(2)
                                          .map((tag) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondary
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  tag.toString(),
                                                  style: const TextStyle(
                                                    color: AppTheme.secondary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                ],
                              ),
                            ),
                            // Average Rating
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatDate(rating['created_at'] ?? ''),
                                  style: const TextStyle(
                                    color: AppTheme.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border, height: 1),
                        const SizedBox(height: 16),

                        // Rating Breakdown
                        _buildExpertRatingRow(
                          'Presentation',
                          rating['presentation_rating'] ?? 0,
                        ),
                        const SizedBox(height: 8),
                        _buildExpertRatingRow(
                          'Taste',
                          rating['taste_rating'] ?? 0,
                        ),
                        const SizedBox(height: 8),
                        _buildExpertRatingRow(
                          'Ingredients',
                          rating['ingredients_rating'] ?? 0,
                        ),
                        const SizedBox(height: 8),
                        _buildExpertRatingRow(
                          'Accuracy',
                          rating['accuracy_rating'] ?? 0,
                        ),

                        // Expert Notes
                        if (rating['notes'] != null &&
                            rating['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: AppTheme.border, height: 1),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Icon(
                                Icons.notes,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Expert Notes',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rating['notes'].toString(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getExpertNotes(String category) {
    switch (category) {
      case 'Presentation':
        return 'Well-crafted garnish and glassware';
      case 'Taste':
        return 'Balanced flavors with good depth';
      case 'Ingredients':
        return 'Fresh, quality ingredients used';
      case 'Accuracy':
        return 'True to classic recipe';
      default:
        return 'No notes available';
    }
  }

  void _showCustomerReviews() async {
    // Fetch actual reviews from API with pagination
    final reviewsData = await _beverageService.getBeverageRatings(
      widget.beverageId,
      page: 1,
      limit: 20,
    );

    if (!mounted) return;

    // ✅ FIXED: Extract ratings array from new response structure
    final ratingsData = reviewsData?['ratings'] as List? ?? [];
    final pagination =
        reviewsData?['pagination'] as Map<String, dynamic>? ?? {};

    if (ratingsData.isEmpty) {
      _toast('No customer reviews yet');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customer Reviews (${pagination['total'] ?? ratingsData.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ratingsData.length,
                itemBuilder: (context, index) {
                  final review = ratingsData[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.glassLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.secondary,
                              child: Text(
                                (review['user']?['name'] ?? 'U')[0]
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review['user']?['name'] ?? 'Anonymous',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(review['created_at'] ?? ''),
                                    style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                                  '${review['rating'] ?? 0}',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (review['comments'] != null &&
                            review['comments'].toString().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            review['comments'].toString(),
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recent';
    }
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
    if (loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (hasError || beverage == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load beverage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  AppTheme.gradientButtonAmber(
                    onPressed: fetchBeverage,
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Extract ratings
    final ratings = beverage!['ratings'] as Map<String, dynamic>? ?? {};
    final avgHuman = ratings['avgHuman'] ?? ratings['avghuman'] ?? 0;
    final countHuman = ratings['countHuman'] ?? ratings['counthuman'] ?? 0;
    final avgExpert = ratings['avgExpert'] ?? ratings['avgexpert'] ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildRatingsSection(avgHuman, countHuman, avgExpert),
          const SizedBox(height: 16),
          _buildDetailsSection(),
          const SizedBox(height: 16),
          _buildActionsSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final photo = beverage!['photo'];
    final name = beverage!['name'] ?? 'Beverage';
    final category =
        beverage!['category'] ?? beverage!['drinkType'] ?? 'Beverage';

    return Stack(
      children: [
        // Image
        if (photo != null && photo.toString().isNotEmpty)
          Image.network(
            photo,
            height: 360,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        else
          _buildPlaceholderImage(),

        // Gradient overlay
        Container(
          height: 360,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: _buildCircleButton(
            Icons.arrow_back_rounded,
            () => Navigator.pop(context),
          ),
        ),

        // Beverage info
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 360,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_bar_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildRatingsSection(
      dynamic avgHuman, dynamic countHuman, dynamic avgExpert) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildRatingCard(
            label: 'SipZy Rating',
            value: 0.0, // Not in API response
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _buildRatingCard(
            label: 'Customer Rating',
            value: avgHuman,
            color: AppTheme.secondary,
            subtitle: '$countHuman reviews',
            onTap: () => setState(() => showReviewsDialog = true),
          ),
          const SizedBox(height: 12),
          _buildRatingCard(
            label: 'Expert Rating',
            value: avgExpert,
            color: Colors.green,
            onTap: () => setState(() => showExpertBreakdown = true),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard({
    required String label,
    required dynamic value,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final ratingValue = (value is num ? value.toDouble() : 0.0);

    return GestureDetector(
      onTap: () {
        {
          if (label == 'Customer Rating') {
            _showCustomerReviews();
          } else if (label == 'Expert Rating') {
            _showExpertRatings();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.star_rounded, color: color, size: 24),
                const SizedBox(width: 6),
                Text(
                  ratingValue.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final description = beverage!['description'] ?? '';
    final price = beverage!['price'] ?? 0;
    final baseType = beverage!['baseType'] ?? beverage!['basetype'] ?? 'N/A';
    final category = beverage!['category'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              _buildDetailRow('Description', description),
            _buildDetailRow('Price', '₹$price'),
            _buildDetailRow('Base Drink', baseType),
            _buildDetailRow('Category', category),
          ],
        ),
      ),
    );
  }

// Helper method for rating breakdown rows
  Widget _buildExpertRatingRow(String label, dynamic rating) {
    final ratingValue = (rating is num ? rating.toDouble() : 0.0);

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
              value: ratingValue / 5,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          ratingValue.toStringAsFixed(1),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // ================= ADD RATING =================
          Expanded(
            child: SizedBox(
              height: 48,
              child: AppTheme.gradientButtonAmber(
                onPressed: () => _showRatingDialog(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Add Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ================= SHARE =================
          _buildIconAction(
            icon: Icons.share_rounded,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ShareModal(
                  onClose: () => Navigator.pop(context),
                  item: {
                    'title': beverage!['name'] ?? 'Beverage',
                    'description': 'Check out this beverage on SipZy!',
                    'url': 'https://sipzy.co.in/beverage/${widget.beverageId}',
                  },
                ),
              );
            },
          ),

          const SizedBox(width: 12),

          // ================= PHOTO UPLOAD =================
          _buildIconAction(
            icon: Icons.camera_alt_rounded,
            onTap: () => _showPhotoUpload(beverage!),
          ),
        ],
      ),
    );
  }

  void _showPhotoUpload(Map bev) async {
    final cameraService = CameraService();

    final photoUrl = await cameraService.pickAndUpload(
      context: context,
      bucket: 'beverage-photos', // ✅ Same bucket as restaurant photos
      folder: 'user-uploads',
      filename: '${bev['id']}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (photoUrl != null) {
      final success = await _beverageService.uploadBeveragePhoto(
        bev['id'].toString(),
        photoUrl,
      );

      if (success) {
        _toast('Photo uploaded successfully!');

        // ✅ ADD: Refresh to fetch the new photo
        final userPhotos = await _fetchUserUploadedBeveragePhotos();
        if (mounted) {
          setState(() {
            _userUploadedPhotos = userPhotos;
          });
        }
      } else {
        _toast('Failed to save photo', isError: true);
      }
    }
  }

  Widget _buildIconAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }
}
