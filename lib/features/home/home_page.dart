import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/restaurant_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../shared/navigation/bottom_nav.dart';
import '../../shared/ui/share_modal.dart';
import '../../shared/utils/keyboard_dismisser.dart';
import '../../core/theme/app_theme.dart';

// Import all the new widgets
import 'widgets/home_header.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/featured_section.dart';
import 'widgets/trending_section.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/loading_skeleton.dart';
import 'widgets/error_state_widget.dart';
import 'dialogs/filter_bottom_sheet.dart';
import 'dialogs/sort_bottom_sheet.dart';
import 'dialogs/city_selector_sheet.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  final _restaurantService = RestaurantService();
  final _userService = UserService();

  List restaurants = [];
  List featuredRestaurants = [];
  List trendingRestaurants = [];
  List<int> bookmarkedIds = [];

  bool loading = true;
  bool hasError = false;
  String searchQuery = '';

  List<String> selectedCuisines = [];
  double minRating = 0;
  double maxDistance = 10;
  double minCost = 0;
  double maxCost = 5000;

  String sortBy = 'rating';

  final baseDrinks = [
    'Whisky',
    'Rum',
    'Vodka',
    'Gin',
    'Beer',
    'Wine',
    'Water',
    'Soda',
    'Milk',
    'Juice'
  ];

  Set<String> selectedBaseDrinks = {};

  final restaurantTypes = [
    'Fine Dining',
    'Casual',
    'Romantic',
    'Gastropub',
    'Brewery'
  ];

  Set<String> selectedRestaurantTypes = {};

  final cuisines = [
    'Indian',
    'Continental',
    'Asian',
    'Mediterranean',
    'Italian',
    'Chinese'
  ];

  final cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
  ];

  String selectedCity = 'Bangalore';

  @override
  void initState() {
    super.initState();
    setState(() {
      searchQuery = '';
      sortBy = 'rating';
    });
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
      setState(() => hasError = true);
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

      setState(() {
        if (locationService.currentCity != null) {
          selectedCity = locationService.currentCity!;
        }
      });

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
        setState(() {
          restaurants = fetchedRestaurants;
          hasError = false;
        });

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
        _toast('Failed to load restaurants', isError: true);
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
          featuredRestaurants = results[0];
          trendingRestaurants = results[1];
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
      final success = await _userService.toggleBookmark(restaurantId);

      if (success) {
        await fetchBookmarks();
        if (mounted) {
          _toast('Bookmark updated');
        }
      }
    } catch (e) {
      print('❌ Toggle bookmark error: $e');
      if (mounted) {
        _toast('Failed to update bookmark', isError: true);
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
        duration: const Duration(seconds: 2),
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
        cuisines: cuisines,
        baseDrinks: baseDrinks,
        restaurantTypes: restaurantTypes,
        initialFilters: FilterData(
          selectedCuisines: selectedCuisines,
          selectedBaseDrinks: selectedBaseDrinks,
          selectedRestaurantTypes: selectedRestaurantTypes,
          minRating: minRating,
          maxDistance: maxDistance,
          minCost: minCost,
          maxCost: maxCost,
        ),
        onApply: (filters) {
          setState(() {
            selectedCuisines = filters.selectedCuisines;
            selectedBaseDrinks = filters.selectedBaseDrinks;
            selectedRestaurantTypes = filters.selectedRestaurantTypes;
            minRating = filters.minRating;
            maxDistance = filters.maxDistance;
            minCost = filters.minCost;
            maxCost = filters.maxCost;
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
          Navigator.pop(context);
          fetchRestaurants();
        },
      ),
    );
  }

  void _showCitySelector() {
    final locationService = LocationService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => CitySelectorSheet(
        cities: cities,
        selectedCity: selectedCity,
        onCitySelected: (city) {
          setState(() {
            selectedCity = city;
            locationService.setCity(city);
          });
          fetchRestaurants();
        },
        onUseCurrentLocation: () async {
          final position =
              await locationService.getCurrentLocation(forceRefresh: true);

          if (mounted) {
            if (position != null && locationService.currentCity != null) {
              setState(() {
                selectedCity = locationService.currentCity!;
              });
              fetchRestaurants();
              _toast('Location updated to ${locationService.currentCity}');
            } else {
              _toast('Could not detect your city', isError: true);
            }
          }
        },
      ),
    );
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
                onCityTap: _showCitySelector,
                searchQuery: searchQuery,
                onSearchChanged: (v) {
                  setState(() => searchQuery = v);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (searchQuery == v) {
                      fetchRestaurants();
                    }
                  });
                },
                hasActiveFilters: selectedCuisines.isNotEmpty ||
                    minRating > 0 ||
                    maxDistance < 10,
                onFiltersTap: _showFilters,
                onSortTap: _showSort,
                sortLabel: _getSortLabel(),
                onExpertCornerTap: () => context.push('/expert-corner'),
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
      return ErrorStateWidget(
        title: 'Unable to load restaurants',
        message: 'Check your connection and try again',
        onRetry: _loadAll,
      );
    }

    if (restaurants.isEmpty &&
        featuredRestaurants.isEmpty &&
        trendingRestaurants.isEmpty) {
      return EmptyStateWidget(
        message: 'No restaurants found',
        submessage:
            searchQuery.isNotEmpty ? 'Try a different search term' : null,
        actionLabel: searchQuery.isNotEmpty ? 'Clear Search' : null,
        onAction: searchQuery.isNotEmpty
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
          if (searchQuery.isEmpty &&
              selectedCuisines.isEmpty &&
              minRating == 0 &&
              featuredRestaurants.isNotEmpty)
            FeaturedSection(
              restaurants: featuredRestaurants,
              cardBuilder: (restaurant) => _buildRestaurantCard(restaurant),
            ),

          // Trending Section
          if (searchQuery.isEmpty &&
              selectedCuisines.isEmpty &&
              minRating == 0 &&
              trendingRestaurants.isNotEmpty)
            TrendingSection(
              restaurants: trendingRestaurants,
              cardBuilder: (restaurant) => _buildRestaurantCard(restaurant),
            ),

          // All/Search Results
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
          ...restaurants.map((restaurant) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRestaurantCard(restaurant),
              )),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map restaurant) {
    final restaurantId = restaurant['id'];
    final isBookmarked = bookmarkedIds.contains(restaurantId);
    final name = restaurant['name'] ?? 'Restaurant';

    return RestaurantCard(
      restaurant: restaurant,
      isBookmarked: isBookmarked,
      onBookmarkTap: () => toggleBookmark(restaurantId.toString()),
      onShareTap: () {
        showDialog(
          context: context,
          builder: (context) => ShareModal(
            onClose: () => Navigator.pop(context),
            item: {
              'title': name,
              'description': 'Check out this restaurant!',
              'url': 'https://sipzy.co.in/restaurant/$restaurantId',
            },
          ),
        );
      },
      onCardTap: () => context.push('/restaurant/$restaurantId'),
    );
  }
}
