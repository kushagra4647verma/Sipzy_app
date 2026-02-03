import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/restaurant_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../shared/utils/keyboard_dismisser.dart';
import '../../core/theme/app_theme.dart';

// Dialogs
import 'dialogs/city_selector_sheet.dart';
import 'dialogs/filter_bottom_sheet.dart';
import 'dialogs/sort_bottom_sheet.dart';

// Widgets
import 'widgets/home_header.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/featured_section.dart';
import 'widgets/trending_section.dart';
import 'widgets/loading_skeleton.dart';
import 'widgets/error_state_widget.dart';
import 'widgets/empty_state_widget.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _restaurantService = RestaurantService();
  final _userService = UserService();

  // State
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> featuredRestaurants = [];
  List<Map<String, dynamic>> trendingRestaurants = [];
  List<int> bookmarkedIds = [];

  bool loading = true;
  bool hasError = false;
  String searchQuery = '';

  // Filters
  List<String> selectedCuisines = [];
  Set<String> selectedBaseDrinks = {};
  Set<String> selectedRestaurantTypes = {};
  double minRating = 0;
  double maxDistance = 10;
  double minCost = 0;
  double maxCost = 5000;

  String sortBy = 'rating';
  String selectedCity = 'Bangalore';

  final cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadAll();
  }

  Future<void> _initializeLocation() async {
    final locationService = LocationService();
    final hasPermission = await locationService.requestLocationPermission();

    if (hasPermission) {
      final position = await locationService.getCurrentLocation();

      if (mounted && position != null && locationService.currentCity != null) {
        setState(() {
          selectedCity = locationService.currentCity!;
        });
      }
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      await Future.wait([fetchRestaurants(), fetchBookmarks()]);
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => hasError = true);
      }
    }
  }

  Future<void> fetchRestaurants() async {
    setState(() {
      loading = true;
      hasError = false;
    });

    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      final cityToUse = locationService.currentCity ?? selectedCity;

      if (mounted && locationService.currentCity != null) {
        setState(() {
          selectedCity = locationService.currentCity!;
        });
      }

      final fetchedRestaurants = await _restaurantService.getRestaurants(
        city: cityToUse,
        lat: position?.latitude,
        lon: position?.longitude,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        cuisine: selectedCuisines.isNotEmpty ? selectedCuisines.first : null,
        minRating: minRating > 0 ? minRating : null,
        maxDistance: maxDistance < 10 ? maxDistance : null,
        sortBy: sortBy,
      );

      if (mounted) {
        // In home_page.dart, after fetching restaurants
        setState(() {
          restaurants = List<Map<String, dynamic>>.from(
            fetchedRestaurants.map((r) {
              print('🔍 Restaurant data: $r'); // Add this line
              return r;
            }),
          );
        });

        // Fetch featured and trending only if no search/filters
        if (searchQuery.isEmpty && selectedCuisines.isEmpty && minRating == 0) {
          await _fetchFeaturedAndTrending(
            city: cityToUse,
            lat: position?.latitude,
            lon: position?.longitude,
          );
        } else {
          setState(() {
            featuredRestaurants = [];
            trendingRestaurants = [];
          });
        }
      }
    } catch (e) {
      print('❌ Fetch restaurants error: $e');
      if (mounted) {
        setState(() => hasError = true);
        _showToast('Failed to load restaurants', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _fetchFeaturedAndTrending({
    String? city,
    double? lat,
    double? lon,
  }) async {
    try {
      final results = await Future.wait([
        _restaurantService.getFeaturedRestaurants(lat: lat, lon: lon),
        if (city != null && city.isNotEmpty)
          _restaurantService.getTrendingRestaurants(city: city)
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          featuredRestaurants = List<Map<String, dynamic>>.from(
            (results[0] as List).map((r) => r is Map<String, dynamic> ? r : {}),
          );
          trendingRestaurants = List<Map<String, dynamic>>.from(
            (results[1] as List).map((r) => r is Map<String, dynamic> ? r : {}),
          );
        });
      }
    } catch (e) {
      print('⚠️ Failed to fetch featured/trending: $e');
    }
  }

  Future<void> fetchBookmarks() async {
    try {
      final bookmarksList = await _userService.getBookmarks();

      if (mounted) {
        setState(() {
          bookmarkedIds = bookmarksList
              .map((e) {
                final id = e['restaurantId'] ?? e['restaurantid'] ?? e['id'];
                if (id == null) return 0;
                if (id is int) return id;
                if (id is String) return int.tryParse(id) ?? 0;
                if (id is num) return id.toInt();
                return 0;
              })
              .where((id) => id != 0)
              .toList();
        });
      }
    } catch (e) {
      print('⚠️ Failed to fetch bookmarks: $e');
    }
  }

  Future<void> toggleBookmark(String restaurantId) async {
    try {
      final success = await _userService.addBookmark(restaurantId);

      if (success) {
        await fetchBookmarks();
        if (mounted) {
          _showToast('Bookmark updated');
        }
      }
    } catch (e) {
      print('❌ Toggle bookmark error: $e');
      if (mounted) {
        _showToast('Failed to update bookmark', isError: true);
      }
    }
  }

  String _getSortLabel() {
    switch (sortBy) {
      case 'rating':
        return 'Highest Rating';
      case 'distance':
        return 'Nearest First';
      case 'cost_low':
        return 'Cost: Low to High';
      case 'cost_high':
        return 'Cost: High to Low';
      default:
        return 'Highest Rating';
    }
  }

  void _showToast(String msg, {bool isError = false}) {
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CitySelectorSheet(
        selectedCity: selectedCity,
        cities: cities,
        onCitySelected: (city) {
          setState(() => selectedCity = city);
          fetchRestaurants();
        },
        onToast: _showToast,
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => FilterBottomSheet(
        selectedCuisines: selectedCuisines,
        selectedBaseDrinks: selectedBaseDrinks,
        selectedRestaurantTypes: selectedRestaurantTypes,
        minRating: minRating,
        maxDistance: maxDistance,
        minCost: minCost,
        maxCost: maxCost,
        onApply: (filters) {
          setState(() {
            selectedCuisines = filters['selectedCuisines'];
            selectedBaseDrinks = filters['selectedBaseDrinks'];
            selectedRestaurantTypes = filters['selectedRestaurantTypes'];
            minRating = filters['minRating'];
            maxDistance = filters['maxDistance'];
            minCost = filters['minCost'];
            maxCost = filters['maxCost'];
          });
          fetchRestaurants();
        },
      ),
    );
  }

  void _showSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => SortBottomSheet(
        currentSort: sortBy,
        onSortSelected: (value) {
          setState(() => sortBy = value);
          fetchRestaurants();
        },
      ),
    );
  }

  void _handleSearchChanged(String query) {
    setState(() => searchQuery = query);
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery == query && mounted) {
        fetchRestaurants();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Column(
            children: [
              HomeHeader(
                selectedCity: selectedCity,
                searchQuery: searchQuery,
                hasActiveFilters: selectedCuisines.isNotEmpty ||
                    minRating > 0 ||
                    maxDistance < 10,
                sortLabel: _getSortLabel(),
                onCityTap: _showCitySelector,
                onFilterTap: _showFilters,
                onSortTap: _showSort,
                onSearchChanged: _handleSearchChanged,
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNav(active: 'sipzy'),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const LoadingSkeleton();
    }

    if (hasError) {
      return ErrorStateWidget(onRetry: _loadAll);
    }

    if (restaurants.isEmpty &&
        featuredRestaurants.isEmpty &&
        trendingRestaurants.isEmpty) {
      return EmptyStateWidget(
        searchQuery: searchQuery,
        onClearSearch: searchQuery.isNotEmpty
            ? () {
                setState(() => searchQuery = '');
                fetchRestaurants();
              }
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primary,
      backgroundColor: AppTheme.card,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured Section
          if (searchQuery.isEmpty && selectedCuisines.isEmpty && minRating == 0)
            FeaturedSection(
              featuredRestaurants: featuredRestaurants,
              bookmarkedIds: bookmarkedIds,
              onBookmarkToggle: toggleBookmark,
            ),

          // Trending Section
          if (searchQuery.isEmpty && selectedCuisines.isEmpty && minRating == 0)
            TrendingSection(
              trendingRestaurants: trendingRestaurants,
              bookmarkedIds: bookmarkedIds,
              onBookmarkToggle: toggleBookmark,
            ),

          // All/Search Results Header
          Text(
            searchQuery.isNotEmpty ||
                    selectedCuisines.isNotEmpty ||
                    minRating > 0
                ? 'Results (${restaurants.length})'
                : 'Nearby Restaurants',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Restaurant List
          ...restaurants.map((restaurant) {
            final restaurantId = restaurant['id'] ?? 0;
            final isBookmarked = bookmarkedIds.contains(restaurantId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RestaurantCard(
                restaurant: restaurant,
                isBookmarked: isBookmarked,
                onBookmarkToggle: toggleBookmark,
              ),
            );
          }),
        ],
      ),
    );
  }
}
