// lib/services/user_service.dart
// ✅ FIXED: Removed photo upload methods (moved to specific services)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';

class UserService {
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

  // ============ USER PROFILE ============

  /// GET /api/users/get_my_profile
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_my_profile'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get profile error: $e');
      return null;
    }
  }

  /// PATCH /api/users/patch_my_profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/patch_my_profile'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Update profile error: $e');
      return false;
    }
  }

  // ============ STATS & BADGES ============

  /// GET /api/users/get_stats/:userId/stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_stats/$userId/stats'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return {
        'ratingsCount': 0,
        'friendsCount': 0,
        'badgesCount': 0,
        'bookmarksCount': 0,
        'diaryEntriesCount': 0,
      };
    } catch (e) {
      print('❌ Get stats error: $e');
      return {
        'ratingsCount': 0,
        'friendsCount': 0,
        'badgesCount': 0,
        'bookmarksCount': 0,
        'diaryEntriesCount': 0,
      };
    }
  }

  /// GET /api/users/get_ratings/:userId/ratings
  Future<Map<String, dynamic>?> getUserRatings(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_ratings/$userId/ratings'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true ? data['data'] : data;
      }
      return null;
    } catch (e) {
      print('❌ Get user ratings error: $e');
      return null;
    }
  }

  /// GET /api/users/get_my_badges
  Future<List<Map<String, dynamic>>> getBadges() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/get_my_badges'),
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
      print('❌ Get badges error: $e');
      return [];
    }
  }

  /// POST /api/users/post_my_badges/:badgeId/claim
  Future<bool> claimBadge(String badgeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/post_my_badges/$badgeId/claim'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Claim badge error: $e');
      return false;
    }
  }

  // ============ DIARY ============

  /// GET /api/diary/get_diary
  Future<List<Map<String, dynamic>>> getDiary() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/diary/get_diary'),
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
      print('❌ Get diary error: $e');
      return [];
    }
  }

  /// POST /api/diary/post_diary
  Future<bool> addDiaryEntry(Map<String, dynamic> entry) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/diary/post_diary'),
            headers: headers,
            body: jsonEncode(entry),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Add diary error: $e');
      return false;
    }
  }

  /// PATCH /api/diary/patch_diary/:entryId
  Future<bool> updateDiaryEntry(
      String entryId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/diary/patch_diary/$entryId'),
            headers: headers,
            body: jsonEncode(updates),
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Update diary error: $e');
      return false;
    }
  }

  /// DELETE /api/diary/delete_diary/:entryId
  Future<bool> deleteDiaryEntry(String entryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/diary/delete_diary/$entryId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Delete diary error: $e');
      return false;
    }
  }

  // ============ BOOKMARKS ============

  /// GET /api/bookmarks/get_bookmarks
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/bookmarks/get_bookmarks'),
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
      print('❌ Get bookmarks error: $e');
      return [];
    }
  }

  /// POST /api/bookmarks/post_bookmark/:restaurantId
  Future<bool> addBookmark(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/bookmarks/post_bookmark/$restaurantId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Add bookmark error: $e');
      return false;
    }
  }

  /// DELETE /api/bookmarks/delete_bookmark/:restaurantId
  Future<bool> removeBookmark(String restaurantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/bookmarks/delete_bookmark/$restaurantId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Remove bookmark error: $e');
      return false;
    }
  }

  // ============ FRIENDS ============

  /// GET /api/friends/get_friend
  Future<List<Map<String, dynamic>>> getFriends() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/friends/get_friend'),
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
      print('❌ Get friends error: $e');
      return [];
    }
  }

  /// POST /api/friends/post_friend/:friendId
  Future<bool> addFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/friends/post_friend/$friendId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Add friend error: $e');
      return false;
    }
  }

  /// DELETE /api/friends/delete_friend/:friendId
  Future<bool> removeFriend(String friendId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/friends/delete_friend/$friendId'),
            headers: headers,
          )
          .timeout(EnvConfig.requestTimeout);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Remove friend error: $e');
      return false;
    }
  }

  /// POST /api/friends/phone
  Future<Map<String, dynamic>?> addFriendByPhone(String phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/friends/phone'),
            headers: headers,
            body: jsonEncode({'phone': phone}),
          )
          .timeout(EnvConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Add friend by phone error: $e');
      return null;
    }
  }

  /// GET /api/friends/search?query={name}
  Future<List<Map<String, dynamic>>> searchFriends(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/friends/search?query=${Uri.encodeComponent(query)}'),
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
      print('❌ Search friends error: $e');
      return [];
    }
  }

  // ============ HEALTH CHECK ============

  /// GET /api/users/health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check error: $e');
      return false;
    }
  }
}
