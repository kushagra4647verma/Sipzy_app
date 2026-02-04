import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/restaurant_service.dart';
import '../../services/beverage_service.dart';
import '../../services/camera_service.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/ui/invite_friends_modal.dart';
import '../../shared/ui/group_mix_magic_dialog.dart';
import '../../shared/ui/share_modal.dart';
import '../../features/models/restaurant_model.dart';

class RestaurantDetail extends StatefulWidget {
  final Map<String, dynamic> user;
  final String restaurantId;

  const RestaurantDetail({
    super.key,
    required this.user,
    required this.restaurantId,
  });

  @override
  State<RestaurantDetail> createState() => _RestaurantDetailState();
}

class _RestaurantDetailState extends State<RestaurantDetail>
    with SingleTickerProviderStateMixin {
  final _restaurantService = RestaurantService();
  final _beverageService = BeverageService();
  final _eventService = EventService();
  final _userService = UserService();

  Restaurant? restaurant;
  List<String> _userUploadedPhotos = [];
  List beverages = [];
  List filteredBeverages = [];
  List topSipzyBeverages = [];
  List customerFavorites = [];
  List expertRecommendations = [];
  List events = [];

  bool loading = true;
  bool hasError = false;
  bool alcoholicOnly = true;
  bool isBookmarked = false;
  bool showInviteModal = false;

  String searchQuery = '';
  String sortBy = 'recommended';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    setState(() {
      alcoholicOnly = true;
      searchQuery = '';
      sortBy = 'recommended';
    });

    fetchRestaurant();
    checkBookmark();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchUserUploadedBeveragePhotos() async {
    try {
      final supabase = Supabase.instance.client;

      // List all files in the user-uploads folder for this restaurant's beverages
      final result = await supabase.storage
          .from('beverage-photos')
          .list(path: 'user-uploads');

      if (result.isEmpty) return [];

      // Get beverage IDs from current restaurant
      final beverageIds = beverages.map((b) => b['id'].toString()).toSet();

      // Filter photos that belong to this restaurant's beverages
      final photos = <String>[];
      for (final file in result) {
        final fileName = file.name;

        // Check if this photo belongs to any beverage in this restaurant
        // Format: {beverageId}_{timestamp}.jpg
        final beverageId = fileName.split('_').first;

        if (beverageIds.contains(beverageId)) {
          final photoUrl = supabase.storage
              .from('beverage-photos')
              .getPublicUrl('user-uploads/$fileName');
          photos.add(photoUrl);
        }
      }

      print('📸 Found ${photos.length} user-uploaded beverage photos');
      return photos;
    } catch (e) {
      print('❌ Error fetching user-uploaded photos: $e');
      return [];
    }
  }

  void _showPhotoUpload(Map bev) async {
    final cameraService = CameraService();

    final photoUrl = await cameraService.pickAndUpload(
      context: context,
      bucket: 'beverage-photos',
      folder: 'user-uploads',
      filename: '${bev['id']}_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (photoUrl != null) {
      _toast('Photo uploaded successfully!');

      // ✅ Refresh to fetch the new photo
      final userPhotos = await _fetchUserUploadedBeveragePhotos();
      if (mounted) {
        setState(() {
          _userUploadedPhotos = userPhotos;
        });
      }
    }
  }

  Future<void> fetchRestaurant() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final results = await Future.wait([
        _restaurantService.getRestaurant(widget.restaurantId),
        _beverageService.getRestaurantBeverages(widget.restaurantId),
        _eventService.getRestaurantEvents(widget.restaurantId),
      ]);

      if (!mounted) return;

      setState(() {
        restaurant = results[0] as Restaurant?;
        beverages = results[1] as List;
        events = results[2] as List;
        expertRecommendations = [];

        _categorizeBeverages();
        filterAndSort();

        hasError = restaurant == null;
      });

      // ✅ Fetch user-uploaded beverage photos after beverages are loaded
      if (mounted && beverages.isNotEmpty) {
        final userPhotos = await _fetchUserUploadedBeveragePhotos();
        if (mounted) {
          setState(() {
            _userUploadedPhotos = userPhotos; // Add this field
          });
        }
      }
    } catch (e) {
      print('❌ Fetch restaurant error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _toast('Failed to load restaurant', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _categorizeBeverages() {
    // Top SipZy beverages (highest sipzy_rating)
    final sorted = [...beverages];
    sorted.sort((a, b) => ((b['sipzy_rating'] ?? 0) as num)
        .compareTo((a['sipzy_rating'] ?? 0) as num));
    topSipzyBeverages = sorted.take(5).toList();

    // Customer favorites (highest avgHuman rating)
    sorted.sort((a, b) {
      final aRating =
          (a['ratings']?['avgHuman'] ?? a['ratings']?['avghuman'] ?? 0) as num;
      final bRating =
          (b['ratings']?['avgHuman'] ?? b['ratings']?['avghuman'] ?? 0) as num;
      return bRating.compareTo(aRating);
    });
    customerFavorites = sorted.take(5).toList();
  }

  Future<void> checkBookmark() async {
    try {
      final bookmarks = await _userService.getBookmarks();

      if (mounted) {
        setState(() {
          isBookmarked = bookmarks.any((b) =>
              b['restaurantid']?.toString() == widget.restaurantId ||
              b['id']?.toString() == widget.restaurantId);
        });
      }
    } catch (e) {
      print('⚠️ Failed to check bookmark: $e');
    }
  }

  Future<void> toggleBookmark() async {
    try {
      final success = await _userService.addBookmark(widget.restaurantId);

      if (success) {
        setState(() => isBookmarked = !isBookmarked);
        _toast(isBookmarked ? 'Bookmarked!' : 'Bookmark removed');
        checkBookmark();
      }
    } catch (e) {
      print('❌ Toggle bookmark error: $e');
      _toast('Failed to update bookmark', isError: true);
    }
  }

  void filterAndSort() {
    List filtered = beverages.where((b) {
      final category = (b['category'] ?? '').toString().toLowerCase();
      final isAlcoholic =
          category.contains('alcohol') || category == 'alcoholic';
      return isAlcoholic == alcoholicOnly;
    }).toList();

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final name = (b['name'] ?? '').toString().toLowerCase();
        final drinkType =
            (b['drinkType'] ?? b['drinktype'] ?? '').toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        return name.contains(query) || drinkType.contains(query);
      }).toList();
    }

    if (sortBy == 'price_low') {
      filtered.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
    } else if (sortBy == 'price_high') {
      filtered.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
    }

    setState(() => filteredBeverages = filtered);
  }

  void callRestaurant() async {
    final phone = restaurant?['phone'];
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void openMaps() async {
    final lat = restaurant?['latitude'] ?? restaurant?['lat'];
    final lon = restaurant?['longitude'] ?? restaurant?['lon'];

    if (lat != null && lon != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
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

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact & Links',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Phone
          if (restaurant!.phone.isNotEmpty)
            _buildContactItem(
              Icons.phone,
              restaurant!.phone,
              () => callRestaurant(),
            ),

          // Email
          if (restaurant!.contactEmail != null)
            _buildContactItem(
              Icons.email,
              restaurant!.contactEmail!,
              () async {
                final uri = Uri.parse('mailto:${restaurant!.contactEmail}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),

          // Website
          if (restaurant!.websiteUrl != null)
            _buildContactItem(
              Icons.language,
              restaurant!.websiteUrl!,
              () async {
                var url = restaurant!.websiteUrl!;
                if (!url.startsWith('http')) {
                  url = 'https://$url';
                }
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication); // ✅ Added mode
                }
              },
            ),

          // Social Media
          const SizedBox(height: 16),
          const Text(
            'Follow Us',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (restaurant!.instaLink != null &&
                  restaurant!.instaLink!.isNotEmpty)
                _buildSocialButton(
                  Icons.camera_alt,
                  Colors.purple,
                  () =>
                      _launchSocialUrl(restaurant!.instaLink!), // ✅ Use helper
                ),
              if (restaurant!.facebookLink != null &&
                  restaurant!.facebookLink!.isNotEmpty)
                _buildSocialButton(
                  Icons.facebook,
                  Colors.blue,
                  () => _launchSocialUrl(
                      restaurant!.facebookLink!), // ✅ Use helper
                ),
              if (restaurant!.twitterLink != null &&
                  restaurant!.twitterLink!.isNotEmpty)
                _buildSocialButton(
                  Icons.flutter_dash,
                  Colors.lightBlue,
                  () => _launchSocialUrl(
                      restaurant!.twitterLink!), // ✅ Use helper
                ),
            ],
          ),
        ],
      ),
    );
  }

// ✅ ADD THIS NEW HELPER METHOD
  Future<void> _launchSocialUrl(String url) async {
    try {
      // Clean and validate the URL
      String cleanUrl = url.trim();

      // If it's just a username or handle, skip it
      if (cleanUrl.isEmpty || cleanUrl.length < 5) {
        _toast('Invalid social media link', isError: true);
        return;
      }

      // Add https:// if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      // Try to parse the URL
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null) {
        _toast('Invalid URL format', isError: true);
        return;
      }

      // Check if we can launch it
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // ✅ Force external browser
        );
      } else {
        _toast('Cannot open this link', isError: true);
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      _toast('Failed to open link', isError: true);
    }
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildOpeningHoursSection() {
    final hours = restaurant!.openingHours;
    if (hours.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Opening Hours',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: hours.map<Widget>((daySchedule) {
                final day = daySchedule['day'] ?? '';
                final isClosed = daySchedule['isClosed'] ?? false;
                final timeSlots = daySchedule['timeSlots'] as List? ?? [];

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.border.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isClosed)
                        const Text(
                          'Closed',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: timeSlots.map<Widget>((slot) {
                            return Text(
                              '${slot['openTime']} - ${slot['closeTime']}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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

    if (hasError || restaurant == null) {
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
                    'Failed to load restaurant',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  AppTheme.gradientButtonAmber(
                    onPressed: fetchRestaurant,
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // ================= HEADER =================
              _buildEnhancedHeader(),
              _buildRestaurantInfo(),

              // ================= DISCOVERY FIRST =================
              _buildToggleSearchSort(),
              _buildActionButtons(), // Mix Magic, Filters, etc.
              _buildBeveragesGrid(),

              // ================= SOCIAL + TRUST =================
              _buildTopSipzySection(),
              _buildCustomerFavoritesSection(),
              _buildExpertRecommendationsSection(),

              // ================= DETAILS =================
              _buildAmenitiesSection(),
              _buildOpeningHoursSection(),
              _buildContactSection(),
              _buildPhotoGallerySection(),
              _buildFoodMenuGallery(),
              _buildEventsSection(),

              const SizedBox(height: 80),
            ],
          ),

          // ================= INVITE FRIENDS MODAL =================
          if (showInviteModal)
            InviteFriendsModal(
              open: showInviteModal,
              onClose: () => setState(() => showInviteModal = false),
              user: widget.user,
              restaurant: restaurant!.toMap(),
            ),
        ],
      ),
    );
  }

  // ✅ NEW METHOD: Action buttons section
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Mix Magic Button
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                if (filteredBeverages.isEmpty) {
                  _toast('No beverages available for Mix Magic', isError: true);
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => GroupMixMagicDialog(
                    beverages: beverages,
                    restaurant: restaurant!,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Group Mix Magic',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Share Restaurant Button
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => ShareModal(
                  onClose: () => Navigator.pop(context),
                  item: {
                    'title': restaurant!['name'] ?? 'Restaurant',
                    'description':
                        'Check out this amazing restaurant on SipZy!',
                    'url':
                        'https://sipzy.co.in/restaurant/${widget.restaurantId}',
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.glassLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.share_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    final image = restaurant!['image'] ??
        restaurant!['coverImage'] ??
        restaurant!['coverimage'];
    final name = restaurant!['name'] ?? 'Restaurant';
    final cuisine = (restaurant!['cuisine'] as List?)?.join(', ') ?? '';
    final area = restaurant!['area'] ?? '';
    final distance = restaurant!['distance'] ?? 0;
    final costForTwo =
        restaurant!['cost_for_two'] ?? restaurant!['costForTwo'] ?? 0;

    return Stack(
      children: [
        // Hero Image
        if (image != null && image.toString().isNotEmpty)
          Image.network(
            image,
            height: 360,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholderImage(),
          )
        else
          _buildPlaceholderImage(),

        // Gradient Overlay
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

        // Top Action Buttons
        Positioned(
          top: 40,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleButton(
                Icons.arrow_back_rounded,
                () => Navigator.pop(context),
              ),
              Row(
                children: [
                  _buildCircleButton(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    toggleBookmark,
                  ),
                  const SizedBox(width: 8),
                  _buildCircleButton(
                    Icons.person_add_rounded,
                    () => setState(() => showInviteModal = true),
                  ),
                  if (restaurant!['phone'] != null) ...[
                    const SizedBox(width: 8),
                    _buildCircleButton(Icons.call_rounded, callRestaurant),
                  ],
                  const SizedBox(width: 8),
                  _buildCircleButton(Icons.map_rounded, openMaps),
                ],
              ),
            ],
          ),
        ),

        // Restaurant Info Overlay
        Positioned(
          bottom: 20,
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
              const SizedBox(height: 4),
              if (cuisine.isNotEmpty)
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
                    cuisine,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    area,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Text(
                    ' • ',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '₹$costForTwo for 2',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantInfo() {
    final rating = restaurant!['sipzy_rating'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSipzySection() {
    if (topSipzyBeverages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Top SipZy Beverages',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: topSipzyBeverages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: _buildBeverageCard(topSipzyBeverages[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomerFavoritesSection() {
    if (customerFavorites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Customer Favorites',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: customerFavorites.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: _buildBeverageCard(customerFavorites[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    final amenities = restaurant!['amenities'] as List? ?? [];
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.map((amenity) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.glassLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  amenity.toString(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallerySection() {
    // ✅ FIXED: Only show restaurant gallery + user-uploaded beverage photos
    final restaurantPhotos = restaurant!.gallery;
    final allPhotos = [...restaurantPhotos, ..._userUploadedPhotos];

    if (allPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photo Gallery',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ✅ Show count of user-uploaded beverage photos
              if (_userUploadedPhotos.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.5)),
                  ),
                  child: Text(
                    '+${_userUploadedPhotos.length} user ${_userUploadedPhotos.length == 1 ? 'photo' : 'photos'}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: allPhotos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = allPhotos[index];
              final isUserPhoto = index >= restaurantPhotos.length;

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: Image.network(
                      photo,
                      width: 240,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 240,
                          height: 180,
                          color: AppTheme.glassLight,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 48,
                            color: AppTheme.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  // ✅ Badge for user-uploaded photos
                  if (isUserPhoto)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'User Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFoodMenuGallery() {
    final menuPhotos = restaurant!.foodMenuPics;
    if (menuPhotos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Food Menu',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showFullMenuGallery(),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: menuPhotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Image.network(
                menuPhotos[i],
                width: 300,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 300,
                    height: 200,
                    color: AppTheme.glassLight,
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: AppTheme.textTertiary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showFullMenuGallery() {
    final menuPhotos = restaurant!.foodMenuPics;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.background,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Food Menu',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: menuPhotos.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Image.network(
                    menuPhotos[i],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Upcoming Events',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final event = events[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'] ?? 'Event',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event['description'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event['eventdate'] ?? 'TBA',
                          style: const TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExpertRecommendationsSection() {
    if (expertRecommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expert Recommendations',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: expertRecommendations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final expert = expertRecommendations[index];
              return Container(
                width: 160,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border:
                      Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    // Expert Avatar
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.secondary,
                        child: expert['avatar'] != null
                            ? ClipOval(
                                child: Image.network(
                                  expert['avatar'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                expert['name']?[0] ?? 'E',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    // Expert Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        expert['name'] ?? 'Expert',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${expert['avg_score_given'] ?? 0}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildToggleSearchSort() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.glassLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  children: [
                    _buildToggleButton(
                      icon: Icons.local_bar_rounded,
                      isSelected: alcoholicOnly,
                      onTap: () {
                        setState(() => alcoholicOnly = true);
                        filterAndSort();
                      },
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    _buildToggleButton(
                      icon: Icons.coffee_rounded,
                      isSelected: !alcoholicOnly,
                      onTap: () {
                        setState(() => alcoholicOnly = false);
                        filterAndSort();
                      },
                      color: AppTheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.glassLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: TextField(
                    onChanged: (v) {
                      searchQuery = v;
                      filterAndSort();
                    },
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search beverages...',
                      hintStyle:
                          TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: AppTheme.textSecondary, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showSortSheet(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.glassLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: AppTheme.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeveragesGrid() {
    if (filteredBeverages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 64,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No beverages found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredBeverages.length,
      itemBuilder: (context, index) {
        final bev = filteredBeverages[index];
        return _buildBeverageCard(bev);
      },
    );
  }

  Widget _buildBeverageCard(Map bev) {
    final photo = bev['photo'];
    final name = bev['name'] ?? 'Beverage';
    final price = bev['price'] ?? 0;
    final ratings = bev['ratings'] as Map<String, dynamic>? ?? {};
    final avgHuman = ratings['avgHuman'] ?? ratings['avghuman'] ?? 0;

    return InkWell(
      onTap: () => context.push('/beverage/${bev['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLg),
                  ),
                  child: photo != null && photo.toString().isNotEmpty
                      ? Image.network(
                          photo,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildBeveragePlaceholder();
                          },
                        )
                      : _buildBeveragePlaceholder(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoUpload(bev),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => ShareModal(
                              onClose: () => Navigator.pop(context),
                              item: {
                                'title': bev['name'] ?? 'Beverage',
                                'description':
                                    'Found this amazing drink at ${restaurant!['name']}!',
                                'url':
                                    'https://sipzy.co.in/beverage/${bev['id']}',
                              },
                            ),
                          );
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        avgHuman.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
      height: 360,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildBeveragePlaceholder() {
    return Container(
      height: 120,
      color: AppTheme.glassLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_bar_rounded,
            size: 32,
            color: AppTheme.textTertiary,
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
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : AppTheme.textTertiary,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.black : AppTheme.textTertiary,
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSortOption('Recommended', 'recommended', '⭐'),
              _buildSortOption('Price: Low to High', 'price_low', '↑'),
              _buildSortOption('Price: High to Low', 'price_high', '↓'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, String icon) {
    final isSelected = sortBy == value;

    return InkWell(
      onTap: () {
        setState(() => sortBy = value);
        filterAndSort();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.glassStrong : AppTheme.glassLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
