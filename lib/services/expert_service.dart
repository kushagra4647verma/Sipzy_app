// lib/services/expert_service.dart
// ✅ COMPLETE Expert Service with all backend endpoints integrated
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class ExpertService {
  final _supabase = Supabase.instance.client;
  static const String baseUrl = 'https://api.sipzy.co.in/users/experts';

  // ============ HEADERS ============

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

  // ============ EXPERTS CRUD ============

  /// GET /users/experts?city=Mumbai
  /// Fetches experts, optionally filtered by city
  Future<List<Map<String, dynamic>>> getExperts({String? city}) async {
    try {
      final headers = await _getHeaders();

      var url = baseUrl;
      if (city != null && city.isNotEmpty) {
        url = '$baseUrl?city=${Uri.encodeComponent(city)}';
      }

      print('🔍 Fetching experts from: $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(EnvConfig.requestTimeout);

      print('✅ Experts Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final experts = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Fetched ${experts.length} experts');
          return _normalizeExpertsList(experts);
        }

        if (data is List) {
          return _normalizeExpertsList(List<Map<String, dynamic>>.from(data));
        }
      }

      print('⚠️ No experts found');
      return [];
    } catch (e) {
      print('❌ Get experts error: $e');
      return [];
    }
  }

  /// GET /users/experts/:expertId
  /// Fetches detailed information for a specific expert
  Future<Map<String, dynamic>?> getExpert(String expertId) async {
    try {
      final headers = await _getHeaders();

      print('🔍 Fetching expert details: $expertId');

      final response = await http
          .get(Uri.parse('$baseUrl/$expertId'), headers: headers)
          .timeout(EnvConfig.requestTimeout);

      print('✅ Expert detail response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final expertData = data['success'] == true ? data['data'] : data;

        if (expertData != null) {
          return _normalizeExpert(expertData);
        }
      }
      return null;
    } catch (e) {
      print('❌ Get expert error: $e');
      return null;
    }
  }

  /// GET /users/experts/:expertId/ratings?limit=10
  /// Fetches ratings given by an expert
  Future<List<Map<String, dynamic>>> getExpertRatings(
    String expertId, {
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      print('🔍 Fetching expert ratings: $expertId (limit: $limit)');

      final response = await http
          .get(
            Uri.parse('$baseUrl/$expertId/ratings?limit=$limit'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      print('✅ Expert ratings response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final ratings = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Fetched ${ratings.length} ratings');
          return _normalizeRatingsList(ratings);
        }

        if (data is List) {
          return _normalizeRatingsList(List<Map<String, dynamic>>.from(data));
        }
      }
      return [];
    } catch (e) {
      print('❌ Get expert ratings error: $e');
      return [];
    }
  }

  // ============ DATA NORMALIZATION ============

  /// Normalize list of experts to handle field name variations
  List<Map<String, dynamic>> _normalizeExpertsList(
      List<Map<String, dynamic>> experts) {
    return experts.map((expert) => _normalizeExpert(expert)).toList();
  }

  /// Normalize single expert object
  Map<String, dynamic> _normalizeExpert(Map<String, dynamic> expert) {
    return {
      // ID fields
      'id': expert['user_id'] ?? expert['id'],
      'user_id': expert['user_id'] ?? expert['id'],

      // Basic info
      'name': expert['name'] ?? '',
      'bio': expert['bio'] ?? '',
      'city': expert['city'] ?? '',
      'category': expert['category'] ?? '',
      'status': expert['status'] ?? 'approved',

      // Profile
      'profile_photo': expert['profile_photo'],
      'avatar': expert['profile_photo'] ?? expert['avatar'],

      // Expertise
      'expertise_tags':
          expert['expertise_tags'] is List ? expert['expertise_tags'] : [],

      // Experience
      'years_experience': expert['years_experience'] ?? expert['yearsExp'] ?? 0,
      'yearsExp': expert['years_experience'] ?? expert['yearsExp'] ?? 0,

      // Ratings - handle both formats
      'avg_score': expert['avg_score'] ?? expert['avgRating'] ?? 0,
      'avgRating': expert['avg_score'] ?? expert['avgRating'] ?? 0,
      'total_ratings': expert['total_ratings'] ?? expert['totalRatings'] ?? 0,
      'totalRatings': expert['total_ratings'] ?? expert['totalRatings'] ?? 0,

      // Computed fields
      'verified': true, // All approved experts are verified
      'specialization': expert['category'] ?? 'Sommelier',
    };
  }

  /// Normalize list of ratings
  List<Map<String, dynamic>> _normalizeRatingsList(
      List<Map<String, dynamic>> ratings) {
    return ratings.map((rating) => _normalizeRating(rating)).toList();
  }

  /// Normalize single rating object
  Map<String, dynamic> _normalizeRating(Map<String, dynamic> rating) {
    return {
      // IDs
      'expert_id': rating['expert_id'],
      'beverage_id': rating['beverage_id'],

      // Rating breakdown
      'presentation_rating': rating['presentation_rating'] ?? 0,
      'presentationRating': rating['presentation_rating'] ?? 0,
      'taste_rating': rating['taste_rating'] ?? 0,
      'tasteRating': rating['taste_rating'] ?? 0,
      'ingredients_rating': rating['ingredients_rating'] ?? 0,
      'ingredientsRating': rating['ingredients_rating'] ?? 0,
      'accuracy_rating': rating['accuracy_rating'] ?? 0,
      'accuracyRating': rating['accuracy_rating'] ?? 0,

      // Metadata
      'created_at': rating['created_at'],
      'notes': rating['notes'],

      // Beverage details
      'beverages': rating['beverages'] is Map
          ? {
              'id': rating['beverages']['id'],
              'name': rating['beverages']['name'] ?? '',
              'category': rating['beverages']['category'] ?? '',
              'restaurant_id': rating['beverages']['restaurant_id'],
              'photo': rating['beverages']['photo'],
            }
          : null,

      // Computed average
      'avgRating': _calculateAverageRating(rating),
    };
  }

  /// Calculate average rating from breakdown
  double _calculateAverageRating(Map<String, dynamic> rating) {
    final presentation = rating['presentation_rating'] ?? 0;
    final taste = rating['taste_rating'] ?? 0;
    final ingredients = rating['ingredients_rating'] ?? 0;
    final accuracy = rating['accuracy_rating'] ?? 0;

    return (presentation + taste + ingredients + accuracy) / 4;
  }

  // ============ HEALTH CHECK ============

  /// GET /users/experts/health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Experts health check error: $e');
      return false;
    }
  }

  // ============ HELPER METHODS ============

  /// Safe getter for nested values with fallback
  T _safeGet<T>(
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

  /// Format date string for display
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Recent';
    }
  }
}

// ============ EXPERT CACHE (Optional Performance Enhancement) ============

class ExpertCache {
  static final _expertCache = <String, Map<String, dynamic>>{};
  static final _ratingsCache = <String, List<Map<String, dynamic>>>{};
  static final _timestamps = <String, DateTime>{};
  static const _cacheDuration = Duration(minutes: 10);

  /// Get cached expert data
  static Map<String, dynamic>? getExpert(String expertId) {
    final timestamp = _timestamps['expert_$expertId'];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _expertCache.remove(expertId);
      _timestamps.remove('expert_$expertId');
      return null;
    }

    return _expertCache[expertId];
  }

  /// Cache expert data
  static void setExpert(String expertId, Map<String, dynamic> data) {
    _expertCache[expertId] = data;
    _timestamps['expert_$expertId'] = DateTime.now();
  }

  /// Get cached ratings
  static List<Map<String, dynamic>>? getRatings(String expertId) {
    final timestamp = _timestamps['ratings_$expertId'];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _ratingsCache.remove(expertId);
      _timestamps.remove('ratings_$expertId');
      return null;
    }

    return _ratingsCache[expertId];
  }

  /// Cache ratings
  static void setRatings(String expertId, List<Map<String, dynamic>> data) {
    _ratingsCache[expertId] = data;
    _timestamps['ratings_$expertId'] = DateTime.now();
  }

  /// Clear all cache
  static void clearAll() {
    _expertCache.clear();
    _ratingsCache.clear();
    _timestamps.clear();
  }

  /// Clear specific expert cache
  static void clearExpert(String expertId) {
    _expertCache.remove(expertId);
    _ratingsCache.remove(expertId);
    _timestamps.remove('expert_$expertId');
    _timestamps.remove('ratings_$expertId');
  }
}
