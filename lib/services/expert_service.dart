// lib/services/expert_service.dart
// ✅ FIXED: Complete expert service - removed non-existent endpoints
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class ExpertService {
  final _supabase = Supabase.instance.client;
  static const String baseUrl = 'https://api.sipzy.co.in/users/experts';

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

  // ============ EXPERTS ============

  /// GET /api/experts (with optional city filter)
  Future<List<Map<String, dynamic>>> getExperts({String? city}) async {
    try {
      final headers = await _getHeaders();

      var url = baseUrl;
      if (city != null) {
        url = '$baseUrl?city=${Uri.encodeComponent(city)}';
      }

      print('🔍 Fetching experts from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      print('✅ Experts Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final experts = List<Map<String, dynamic>>.from(data['data']);
          print('✅ Fetched ${experts.length} experts');
          return experts;
        }

        // Fallback for direct array
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }

      print('⚠️ No experts found');
      return [];
    } catch (e) {
      print('❌ Get experts error: $e');
      return [];
    }
  }

  /// GET /api/experts/:expertId
  Future<Map<String, dynamic>?> getExpert(String expertId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/$expertId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get expert error: $e');
      return null;
    }
  }

  /// GET /api/experts/:expertId/ratings
  Future<List<Map<String, dynamic>>> getExpertRatings(
    String expertId, {
    int limit = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/$expertId/ratings?limit=$limit'),
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
      print('❌ Get expert ratings error: $e');
      return [];
    }
  }

  /// GET /api/experts/health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Experts health check error: $e');
      return false;
    }
  }
}
