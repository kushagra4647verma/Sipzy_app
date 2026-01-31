// lib/services/beverage_service.dart
// ✅ FIXED: Complete beverage service with all backend endpoints
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class BeverageService {
  final _supabase = Supabase.instance.client;
  static const String baseUrl = 'https://api.sipzy.co.in/users';

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

  // ============ BEVERAGES CRUD ============

  /// GET /api/beverages
  Future<List<Map<String, dynamic>>> getBeverages() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Get beverages error: $e');
      return [];
    }
  }

  /// GET /api/beverages/:beverageId
  Future<Map<String, dynamic>?> getBeverage(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get beverage error: $e');
      return null;
    }
  }

  /// GET /api/restaurants/:restaurantId/beverages
  /// ✅ MOVED: From restaurant_service to beverage_service
  Future<List<Map<String, dynamic>>> getRestaurantBeverages(
      String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/restaurants/$restaurantId/beverages'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('❌ Get restaurant beverages error: $e');
      return [];
    }
  }

  // ============ RATINGS ============

  /// GET /api/beverages/:beverageId/ratings
  Future<Map<String, dynamic>?> getBeverageRatings(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId/ratings'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get beverage ratings error: $e');
      return null;
    }
  }

  /// POST /api/beverages/:beverageId/ratings
  /// ✅ FIXED: Changed from /rate to /ratings
  Future<bool> rateBeverage(
    String beverageId,
    int rating, {
    String? comments,
  }) async {
    try {
      final headers = await _getHeaders();

      final body = {
        'rating': rating,
        if (comments != null) 'comments': comments,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/beverages/$beverageId/ratings'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(EnvConfig.requestTimeout);

      print('📊 Rate beverage response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Rate beverage error: $e');
      return false;
    }
  }

  // ============ PHOTOS ============

  /// GET /api/beverages/:beverageId/photos
  Future<String?> getBeveragePhoto(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId/photos'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['data']; // Returns photo URL string
        }
      }
      return null;
    } catch (e) {
      print('❌ Get beverage photo error: $e');
      return null;
    }
  }

  /// POST /api/beverages/:beverageId/photos
  /// ✅ NEW: Moved from user_service
  Future<bool> uploadBeveragePhoto(
    String beverageId,
    String photoUrl,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/beverages/$beverageId/photos'),
            headers: headers,
            body: jsonEncode({'photo': photoUrl}),
          )
          .timeout(EnvConfig.requestTimeout);

      print('📤 Upload beverage photo: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Upload beverage photo error: $e');
      return false;
    }
  }

  // ============ EXPERT RATINGS ============

  /// GET /api/beverages/:beverageId/expert-rating
  /// ✅ NEW: Previously missing endpoint
  Future<Map<String, dynamic>?> getExpertRating(String beverageId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/beverages/$beverageId/expert-rating'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get expert rating error: $e');
      return null;
    }
  }
}
