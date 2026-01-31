// lib/services/restaurant_service.dart
// ✅ FIXED: Complete restaurant service with all backend endpoints
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../../features/models/restaurant_model.dart';
import 'dart:typed_data';
import 'location_service.dart';

class RestaurantService {
  final _supabase = Supabase.instance.client;
  final _locationService = LocationService();
  static const String baseUrl = 'https://api.sipzy.co.in/users/restaurants';

  Future<Map<String, String>> _getHeaders() async {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    final headers = {'Content-Type': 'application/json'};

    if (session?.accessToken != null) {
      headers['Authorization'] = 'Bearer ${session!.accessToken}';
    }

    if (user?.id != null) {
      headers['x-user-id'] = user!.id;
    }

    return headers;
  }

  // ============ WKB PARSING ============
  Map<String, double>? _parseLocationGeometry(String? wkb) {
    if (wkb == null || wkb.isEmpty) return null;

    try {
      if (wkb.length < 50) {
        print('⚠️ WKB too short: ${wkb.length}');
        return null;
      }

      final lonHex = wkb.substring(18, 34);
      final latHex = wkb.substring(34, 50);

      final lonBytes = _hexToBytes(lonHex);
      final latBytes = _hexToBytes(latHex);

      final lon = _bytesToDouble(lonBytes);
      final lat = _bytesToDouble(latBytes);

      print('📍 Parsed WKB: lat=$lat, lon=$lon');

      return {'lat': lat, 'lon': lon};
    } catch (e) {
      print('❌ Error parsing WKB: $e');
      return null;
    }
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  double _bytesToDouble(Uint8List bytes) {
    final byteData = ByteData.sublistView(bytes);
    return byteData.getFloat64(0, Endian.little);
  }

  void _calculateDistanceForRestaurant(
    Map<String, dynamic> restaurant,
    double? userLat,
    double? userLon,
  ) {
    try {
      if (restaurant['location'] != null) {
        final coords = _parseLocationGeometry(restaurant['location']);
        if (coords != null) {
          restaurant['lat'] = coords['lat'];
          restaurant['lon'] = coords['lon'];
          restaurant['latitude'] = coords['lat'];
          restaurant['longitude'] = coords['lon'];
        }
      }

      final lat = restaurant['lat'] ??
          restaurant['latitude'] ??
          restaurant['restaurantLatitude'];
      final lon = restaurant['lon'] ??
          restaurant['longitude'] ??
          restaurant['restaurantLongitude'];

      if (userLat != null && userLon != null && lat != null && lon != null) {
        final restaurantLat =
            lat is num ? lat.toDouble() : double.parse(lat.toString());
        final restaurantLon =
            lon is num ? lon.toDouble() : double.parse(lon.toString());

        final distance = _locationService.calculateDistance(
          userLat,
          userLon,
          restaurantLat,
          restaurantLon,
        );

        restaurant['distance'] = distance;
        print(
            '✅ Calculated distance for ${restaurant['name']}: ${distance.toStringAsFixed(2)} km');
      } else {
        restaurant['distance'] = 0.0;
        print(
            '⚠️ Missing coordinates for ${restaurant['name']} - lat: $lat, lon: $lon, userLat: $userLat, userLon: $userLon');
      }
    } catch (e) {
      print('❌ Error calculating distance for ${restaurant['name']}: $e');
      restaurant['distance'] = 0.0;
    }
  }

  // ============ RESTAURANTS CRUD ============

  /// GET /api/restaurants
  Future<List<Map<String, dynamic>>> getRestaurants({
    String? city,
    double? lat,
    double? lon,
    double? radius,
    String? search,
    String? cuisine,
    double? minRating,
    double? maxDistance,
    String? sortBy,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{};

      if (city != null) params['city'] = city;
      if (lat != null) params['lat'] = lat.toString();
      if (lon != null) params['lon'] = lon.toString();
      if (radius != null) params['radius'] = radius.toString();
      if (search != null) params['search'] = search;
      if (cuisine != null) params['cuisine'] = cuisine;
      if (minRating != null) params['min_rating'] = minRating.toString();
      if (maxDistance != null) params['max_distance'] = maxDistance.toString();
      if (sortBy != null) params['sort_by'] = sortBy;

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);

      print('🌐 Fetching restaurants from: $uri');

      final response = await http
          .get(uri, headers: headers)
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final restaurants = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Fetched ${restaurants.length} restaurants');

          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(restaurant, lat, lon);
          }

          return restaurants;
        }

        if (data is List) {
          final restaurants = List<Map<String, dynamic>>.from(data);
          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(restaurant, lat, lon);
          }
          return restaurants;
        }
      }

      return [];
    } catch (e) {
      print('❌ Get restaurants error: $e');
      return [];
    }
  }

  /// GET /api/restaurants/:restaurantId
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/$restaurantId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final restaurantData = body['data'] as Map<String, dynamic>;

          final position = await _locationService.getCurrentLocation();

          _calculateDistanceForRestaurant(
            restaurantData,
            position?.latitude,
            position?.longitude,
          );

          return Restaurant.fromJson(restaurantData);
        }
      }
      return null;
    } catch (e) {
      print('❌ Get restaurant error: $e');
      return null;
    }
  }

  // ============ LOCATION-BASED QUERIES ============

  /// GET /api/restaurants/by-city/:city
  Future<List<dynamic>> getRestaurantsByCity(String city) async {
    try {
      final headers = await _getHeaders();
      final position = await _locationService.getCurrentLocation();
      final encodedCity = Uri.encodeComponent(city);

      final response = await http
          .get(
            Uri.parse('$baseUrl/by-city/$encodedCity'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurants = data['success'] == true
            ? List<Map<String, dynamic>>.from(data['data'] ?? [])
            : (data is List ? List<Map<String, dynamic>>.from(data) : []);

        for (var restaurant in restaurants) {
          _calculateDistanceForRestaurant(
            restaurant,
            position?.latitude,
            position?.longitude,
          );
        }

        return restaurants;
      }
      return [];
    } catch (e) {
      print('❌ Get restaurants by city error: $e');
      return [];
    }
  }

  /// GET /api/restaurants/nearby/:lat/:lon/:radius
  Future<List<dynamic>> getNearbyRestaurants({
    required double lat,
    required double lon,
    double radius = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/nearby/$lat/$lon/$radius'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurants = data['success'] == true
            ? List<Map<String, dynamic>>.from(data['data'] ?? [])
            : (data is List ? List<Map<String, dynamic>>.from(data) : []);

        for (var restaurant in restaurants) {
          _calculateDistanceForRestaurant(restaurant, lat, lon);
        }

        return restaurants;
      }
      return [];
    } catch (e) {
      print('❌ Get nearby restaurants error: $e');
      return [];
    }
  }

  /// GET /api/restaurants/trending/:city
  Future<List<Map<String, dynamic>>> getTrendingRestaurants({
    required String city,
  }) async {
    try {
      final headers = await _getHeaders();
      final encodedCity = Uri.encodeComponent(city);
      final position = await _locationService.getCurrentLocation();

      final response = await http
          .get(
            Uri.parse('$baseUrl/trending/$encodedCity'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded == null) {
          return [];
        }

        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          final restaurants = List<Map<String, dynamic>>.from(decoded['data']);

          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(
              restaurant,
              position?.latitude,
              position?.longitude,
            );
          }

          return restaurants;
        }
      }

      return [];
    } catch (e) {
      print('❌ Get trending restaurants error: $e');
      return [];
    }
  }

  /// GET /api/restaurants/featured/:lat/:lon
  Future<List<Map<String, dynamic>>> getFeaturedRestaurants({
    double? lat,
    double? lon,
  }) async {
    try {
      if (lat == null || lon == null) {
        print('⚠️ Location not available for featured restaurants');
        return [];
      }

      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse('$baseUrl/featured/$lat/$lon'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['data'] != null) {
          final restaurants = List<Map<String, dynamic>>.from(decoded['data']);

          for (var restaurant in restaurants) {
            _calculateDistanceForRestaurant(restaurant, lat, lon);
          }

          return restaurants;
        }
      }

      return [];
    } catch (e) {
      print('❌ Get featured restaurants error: $e');
      return [];
    }
  }

  // ============ RATINGS ============

  /// GET /api/restaurants/:restaurantId/ratings
  Future<Map<String, dynamic>?> getRestaurantRatings(
      String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/$restaurantId/ratings'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get restaurant ratings error: $e');
      return null;
    }
  }

  /// POST /api/restaurants/:restaurantId/rate
  Future<bool> rateRestaurant(
      String restaurantId, Map<String, dynamic> rating) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/$restaurantId/rate'),
            headers: headers,
            body: jsonEncode(rating),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Rate restaurant error: $e');
      return false;
    }
  }

  // ============ PHOTOS ============

  /// GET /api/restaurants/:restaurantId/menu-photos
  Future<List> getMenuPhotos(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/$restaurantId/menu-photos'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get menu photos error: $e');
      return [];
    }
  }

  /// GET /api/restaurants/:restaurantId/food-gallery
  Future<List> getFoodGallery(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/$restaurantId/food-gallery'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true
            ? (data['data'] ?? [])
            : (data is List ? data : []);
      }
      return [];
    } catch (e) {
      print('❌ Get food gallery error: $e');
      return [];
    }
  }

  /// POST /api/restaurants/:restaurantId/photos
  /// ✅ NEW: Moved from user_service
  Future<bool> uploadRestaurantPhotos(
    String restaurantId,
    List<String> photoUrls,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/$restaurantId/photos'),
            headers: headers,
            body: jsonEncode({'photos': photoUrls}),
          )
          .timeout(EnvConfig.requestTimeout);

      print('📤 Upload restaurant photos: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Upload restaurant photos error: $e');
      return false;
    }
  }
}
