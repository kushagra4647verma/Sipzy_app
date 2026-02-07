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
  List<String> bookmarkedIds = [];

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
  String? selectedArea;
  // ✅ Track if user manually selected city vs auto-detected
  bool isManualCitySelection = false;

  final cities = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Hyderabad',
  ];

  // ✅ City center coordinates for manual selection
  final Map<String, Map<String, double>> cityCenters = {
    'Mumbai': {'lat': 19.0760, 'lon': 72.8777},
    'Delhi': {'lat': 28.7041, 'lon': 77.1025},
    'Bangalore': {'lat': 12.9716, 'lon': 77.5946},
    'Hyderabad': {'lat': 17.3850, 'lon': 78.4867},
  };

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
          selectedArea = locationService.currentArea;
          isManualCitySelection = false; // ✅ Auto-detected
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

      // ✅ Use different coordinates based on selection type
      double? lat;
      double? lon;
      String cityToUse = selectedCity;

      if (isManualCitySelection) {
        // Use city center coordinates for manually selected city
        final center = cityCenters[selectedCity];
        if (center != null) {
          lat = center['lat'];
          lon = center['lon'];
          print('📍 Using city center for $selectedCity: $lat, $lon');
        }
      } else {
        // Use actual GPS location for current location
        final position = await locationService.getCurrentLocation();
        lat = position?.latitude;
        lon = position?.longitude;

        // Update city if GPS detected different city
        if (mounted && locationService.currentCity != null) {
          setState(() {
            selectedCity = locationService.currentCity!;
          });
        }
        cityToUse = locationService.currentCity ?? selectedCity;
        print('📍 Using GPS location: $lat, $lon');
      }

      print('🔍 === FETCH RESTAURANTS ===');
      print('  Search: "${searchQuery.trim()}"');
      print('  City: $cityToUse');
      print('  Manual Selection: $isManualCitySelection');
      print(
          '  Cuisine: ${selectedCuisines.isNotEmpty ? selectedCuisines.first : "none"}');
      print('  Min Rating: ${minRating > 0 ? minRating : "none"}');
      print('  Max Distance: ${maxDistance < 10 ? maxDistance : "none"}');
      print('  Sort: $sortBy');
      print('  Lat/Lon: $lat, $lon');

      List<Map<String, dynamic>> fetchedRestaurants = [];

      // ✅ FIX: Try multiple API approaches for manual city selection
      if (isManualCitySelection &&
          searchQuery.trim().isEmpty &&
          selectedCuisines.isEmpty) {
        print('🌆 Trying city-specific API for manual selection...');

        // Try 1: getRestaurantsByCity (specific endpoint)
        try {
          final result =
              await _restaurantService.getRestaurantsByCity(cityToUse);
          fetchedRestaurants = List<Map<String, dynamic>>.from(
              result.map((r) => r is Map<String, dynamic> ? r : {}));
          print(
              '✅ getRestaurantsByCity returned ${fetchedRestaurants.length} restaurants');
        } catch (e) {
          print('⚠️ getRestaurantsByCity failed: $e');
        }

        // Try 2: If that fails, try nearby with city center coordinates
        if (fetchedRestaurants.isEmpty && lat != null && lon != null) {
          print('🌆 Trying nearby API with large radius...');
          try {
            final result = await _restaurantService.getNearbyRestaurants(
              lat: lat,
              lon: lon,
              radius: 50, // Large radius for city-wide search
            );
            fetchedRestaurants = List<Map<String, dynamic>>.from(
                result.map((r) => r is Map<String, dynamic> ? r : {}));
            print(
                '✅ getNearbyRestaurants returned ${fetchedRestaurants.length} restaurants');
          } catch (e) {
            print('⚠️ getNearbyRestaurants failed: $e');
          }
        }

        // Try 3: Fallback to regular getRestaurants
        if (fetchedRestaurants.isEmpty) {
          print('🌆 Falling back to getRestaurants...');
          fetchedRestaurants = await _restaurantService.getRestaurants(
            city: cityToUse,
            lat: lat,
            lon: lon,
            sortBy: sortBy,
          );
          print(
              '✅ getRestaurants returned ${fetchedRestaurants.length} restaurants');
        }
      } else {
        // ✅ Use standard API call for GPS location or when filters are active
        fetchedRestaurants = await _restaurantService.getRestaurants(
          city: cityToUse,
          lat: lat,
          lon: lon,
          search: searchQuery.trim().isNotEmpty ? searchQuery.trim() : null,
          cuisine: selectedCuisines.isNotEmpty ? selectedCuisines.first : null,
          minRating: minRating > 0 ? minRating : null,
          maxDistance: maxDistance < 10 ? maxDistance : null,
          sortBy: sortBy,
        );
      }

      print('📊 Received ${fetchedRestaurants.length} restaurants from API');

      // ✅ Only apply CLIENT-SIDE filters that API doesn't support
      var filteredRestaurants =
          List<Map<String, dynamic>>.from(fetchedRestaurants);

      // Filter by restaurant type (if API doesn't support this)
      if (selectedRestaurantTypes.isNotEmpty) {
        final beforeCount = filteredRestaurants.length;
        filteredRestaurants = filteredRestaurants.where((r) {
          final type = (r['restaurant_type'] ?? r['restaurantType'] ?? '')
              .toString()
              .toLowerCase();
          return selectedRestaurantTypes
              .any((selected) => type.contains(selected.toLowerCase()));
        }).toList();
        print(
            '🏷️ Restaurant type filter: $beforeCount → ${filteredRestaurants.length}');
      }

      // Filter by cost (if API doesn't support this)
      if (minCost > 0 || maxCost < 5000) {
        final beforeCount = filteredRestaurants.length;
        filteredRestaurants = filteredRestaurants.where((r) {
          final priceRange = r['price_range'] ?? r['priceRange'] ?? 2;
          final costForTwo = priceRange * 500;
          return costForTwo >= minCost && costForTwo <= maxCost;
        }).toList();
        print('💰 Cost filter: $beforeCount → ${filteredRestaurants.length}');
      }

      print('✅ Final filtered count: ${filteredRestaurants.length}');

      if (mounted) {
        setState(() {
          restaurants = filteredRestaurants;
        });

        // ✅ Fetch featured and trending for BOTH current location AND manually selected cities
        final hasActiveFilters = searchQuery.trim().isNotEmpty ||
            selectedCuisines.isNotEmpty ||
            minRating > 0 ||
            selectedRestaurantTypes.isNotEmpty ||
            minCost > 0 ||
            maxCost < 5000;

        if (!hasActiveFilters) {
          print('📌 Fetching featured and trending...');
          await _fetchFeaturedAndTrending(
            city: cityToUse,
            lat: lat,
            lon: lon,
          );
        } else {
          print('🚫 Skipping featured/trending (filters active)');
          setState(() {
            featuredRestaurants = [];
            trendingRestaurants = [];
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ Fetch restaurants error: $e');
      print('Stack trace: $stackTrace');
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
      print('📑 === FETCH BOOKMARKS ===');
      print('📑 Raw response: ${bookmarksList.length} items');

      if (mounted) {
        final ids = <String>[];

        for (var bookmark in bookmarksList) {
          final idValue = bookmark['restaurant_id'] ??
              bookmark['restaurantid'] ??
              bookmark['restaurantId'] ??
              bookmark['id'];

          if (idValue != null) {
            final stringId = idValue.toString();
            if (stringId.isNotEmpty && stringId != '0') {
              ids.add(stringId);
              print('📑 Added bookmark ID: $stringId');
            }
          }
        }

        print('📑 Final bookmark IDs: $ids');

        setState(() {
          bookmarkedIds = ids;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Failed to fetch bookmarks: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> toggleBookmark(String restaurantId) async {
    print('🔖 === TOGGLE BOOKMARK ===');
    print('🔖 Restaurant ID: $restaurantId');
    print('🔖 Current bookmarks: $bookmarkedIds');
    print(
        '🔖 Is currently bookmarked: ${bookmarkedIds.contains(restaurantId)}');

    final wasBookmarked = bookmarkedIds.contains(restaurantId);
    setState(() {
      if (wasBookmarked) {
        bookmarkedIds.remove(restaurantId);
      } else {
        bookmarkedIds.add(restaurantId);
      }
      restaurants = List.from(restaurants);
      featuredRestaurants = List.from(featuredRestaurants);
      trendingRestaurants = List.from(trendingRestaurants);
    });

    try {
      final success = await _userService.addBookmark(restaurantId);
      print('🔖 API response: $success');

      if (!success) {
        if (mounted) {
          setState(() {
            if (wasBookmarked) {
              bookmarkedIds.add(restaurantId);
            } else {
              bookmarkedIds.remove(restaurantId);
            }
          });
          _showToast('Failed to update bookmark', isError: true);
        }
        return;
      }

      await fetchBookmarks();

      if (mounted) {
        _showToast(wasBookmarked ? 'Bookmark removed' : 'Bookmarked!');
      }
    } catch (e, stackTrace) {
      print('❌ Toggle bookmark error: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          if (wasBookmarked) {
            bookmarkedIds.add(restaurantId);
          } else {
            bookmarkedIds.remove(restaurantId);
          }
        });
        _showToast('Failed to update bookmark', isError: true);
      }
    }
  }

  Future<void> _refreshRestaurantData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    fetchRestaurants();
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
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF2A2A2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
          setState(() {
            selectedCity = city;
            isManualCitySelection = true; // ✅ Mark as manual selection
            selectedArea = null; // Clear area for manual selection
          });
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
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
            selectedCuisines = List<String>.from(filters['selectedCuisines']);
            selectedBaseDrinks =
                Set<String>.from(filters['selectedBaseDrinks']);
            selectedRestaurantTypes =
                Set<String>.from(filters['selectedRestaurantTypes']);
            minRating = filters['minRating'] as double;
            maxDistance = filters['maxDistance'] as double;
            minCost = filters['minCost'] as double;
            maxCost = filters['maxCost'] as double;
          });

          print('🎯 Filters applied, fetching restaurants...');
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) => SortBottomSheet(
        currentSort: sortBy,
        onSortSelected: (value) {
          setState(() => sortBy = value);
          print('📊 Sort changed to: $value');
          fetchRestaurants();
        },
      ),
    );
  }

  Timer? _searchDebounce;

  void _handleSearchChanged(String query) {
    setState(() => searchQuery = query);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('🔍 Search triggered: "$query"');
        fetchRestaurants();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
                : isManualCitySelection
                    ? 'Restaurants in $selectedCity'
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
            final restaurantId = restaurant['id']?.toString() ?? '';
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
