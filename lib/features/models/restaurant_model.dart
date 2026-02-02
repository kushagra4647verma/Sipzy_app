import 'dart:convert';

class Restaurant {
  final String id;
  final String ownerId;
  final String name;
  final String bio;
  final String phone;
  final String address;
  final String? addressLine2;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final String? contactEmail;
  final String? websiteUrl;

  final List<String> cuisineTags;
  final List<String> amenities;

  final int priceRange;
  final bool hasAlcohol;
  final bool hasReservation;
  final String? reservationLink;
  final bool isVerified;
  final bool isComplete;

  final String? logoImage;
  final String? coverImage;
  final List<String> gallery;
  final List<String> foodMenuPics;

  final List<dynamic> openingHours;

  final String? instaLink;
  final String? facebookLink;
  final String? twitterLink;
  final String? websiteUrl2;
  final String? googleMapsLink;

  final String? location; // PostGIS geometry
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.bio,
    required this.phone,
    required this.address,
    this.addressLine2,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.contactEmail,
    this.websiteUrl,
    required this.cuisineTags,
    required this.amenities,
    required this.priceRange,
    required this.hasAlcohol,
    required this.hasReservation,
    this.reservationLink,
    required this.isVerified,
    required this.isComplete,
    this.logoImage,
    this.coverImage,
    required this.gallery,
    required this.foodMenuPics,
    required this.openingHours,
    this.instaLink,
    this.facebookLink,
    this.twitterLink,
    this.websiteUrl2,
    this.googleMapsLink,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // ✅ CRITICAL FIX: Safe list parser handles null, empty, and JSON strings
    List<String> parseStringList(dynamic value, String fieldName) {
      if (value == null) return [];

      try {
        if (value is List) {
          return value
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (value is String) {
          if (value.isEmpty) return [];
          // Try to parse as JSON array
          try {
            final decoded = jsonDecode(value);
            if (decoded is List) {
              return decoded
                  .map((e) => e?.toString() ?? '')
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          } catch (_) {
            // Not JSON, treat as single item
            return [value];
          }
        }
      } catch (e) {
        print('⚠️ Error parsing $fieldName: $e');
      }

      return [];
    }

    // ✅ CRITICAL FIX: Handle BOTH opening_hours formats (String JSON vs direct Array)
    List<dynamic> parseOpeningHours(dynamic value) {
      if (value == null) return [];

      try {
        // Format 1: Already a List (from /restaurants?city=Bang)
        if (value is List) {
          print('✅ Opening hours already parsed as List');
          return value;
        }

        // Format 2: JSON String (from /restaurants/{id})
        if (value is String) {
          if (value.isEmpty) return [];

          try {
            final decoded = jsonDecode(value);
            if (decoded is List) {
              print('✅ Successfully parsed opening hours JSON string');
              return decoded;
            } else {
              print(
                  '⚠️ Decoded opening hours is not a List: ${decoded.runtimeType}');
              return [];
            }
          } catch (e) {
            print('❌ Error decoding opening hours JSON: $e');
            print('Opening hours value: $value');
            return [];
          }
        }

        print(
            '⚠️ Opening hours is neither List nor String: ${value.runtimeType}');
      } catch (e) {
        print('❌ Unexpected error parsing opening_hours: $e');
      }

      return [];
    }

    try {
      return Restaurant(
        id: json['id']?.toString() ?? '',
        ownerId:
            json['owner_id']?.toString() ?? json['ownerId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        bio: json['bio']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        addressLine2: json['address_line2']?.toString() ??
            json['addressLine2']?.toString(),
        area: json['area']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        contactEmail: json['contact_email']?.toString() ??
            json['contactEmail']?.toString(),
        websiteUrl:
            json['website_url']?.toString() ?? json['websiteUrl']?.toString(),

        cuisineTags: parseStringList(
            json['cuisine_tags'] ?? json['cuisineTags'], 'cuisine_tags'),
        amenities: parseStringList(json['amenities'], 'amenities'),

        priceRange: (json['price_range'] ?? json['priceRange'] ?? 0) is int
            ? json['price_range'] ?? json['priceRange'] ?? 0
            : int.tryParse((json['price_range'] ?? json['priceRange'] ?? 0)
                    .toString()) ??
                0,

        hasAlcohol: json['has_alcohol'] ?? json['hasAlcohol'] ?? false,
        hasReservation:
            json['has_reservation'] ?? json['hasReservation'] ?? false,
        reservationLink: json['reservation_link']?.toString() ??
            json['reservationLink']?.toString(),
        isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
        isComplete: json['is_complete'] ??
            json['iscomplete'] ??
            json['isComplete'] ??
            false,

        logoImage:
            json['logo_image']?.toString() ?? json['logoImage']?.toString(),
        coverImage:
            json['cover_image']?.toString() ?? json['coverImage']?.toString(),

        gallery: parseStringList(json['gallery'], 'gallery'),
        foodMenuPics: parseStringList(
            json['food_menu_pics'] ?? json['foodMenuPics'], 'food_menu_pics'),

        // ✅ THIS IS THE CRITICAL FIX - properly parse BOTH formats
        openingHours:
            parseOpeningHours(json['opening_hours'] ?? json['openingHours']),

        instaLink:
            json['insta_link']?.toString() ?? json['instaLink']?.toString(),
        facebookLink: json['facebook_link']?.toString() ??
            json['facebookLink']?.toString(),
        twitterLink:
            json['twitter_link']?.toString() ?? json['twitterLink']?.toString(),
        websiteUrl2:
            json['website_url']?.toString() ?? json['websiteUrl']?.toString(),
        googleMapsLink: json['google_maps_link']?.toString() ??
            json['googleMapsLink']?.toString(),

        location: json['location']?.toString(),

        createdAt: json['created_at'] != null || json['createdAt'] != null
            ? DateTime.tryParse(
                (json['created_at'] ?? json['createdAt']).toString())
            : null,
        updatedAt: json['updated_at'] != null || json['updatedAt'] != null
            ? DateTime.tryParse(
                (json['updated_at'] ?? json['updatedAt']).toString())
            : null,
      );
    } catch (e, stackTrace) {
      print('❌ Error creating Restaurant from JSON: $e');
      print('Stack trace: $stackTrace');
      print('JSON keys: ${json.keys}');
      rethrow;
    }
  }

  // Helper to convert to Map for accessing like restaurant['field']
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'owner_id': ownerId,
      'name': name,
      'bio': bio,
      'phone': phone,
      'address': address,
      'address_line2': addressLine2,
      'addressLine2': addressLine2,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
      'contactemail': contactEmail,
      'contact_email': contactEmail,
      'websiteurl': websiteUrl,
      'website_url': websiteUrl,
      'cuisineTags': cuisineTags,
      'cuisine_tags': cuisineTags,
      'cuisine': cuisineTags, // Alias for compatibility
      'amenities': amenities,
      'priceRange': priceRange,
      'price_range': priceRange,
      'hasAlcohol': hasAlcohol,
      'has_alcohol': hasAlcohol,
      'hasReservation': hasReservation,
      'has_reservation': hasReservation,
      'reservationLink': reservationLink,
      'reservation_link': reservationLink,
      'isVerified': isVerified,
      'is_verified': isVerified,
      'iscomplete': isComplete,
      'is_complete': isComplete,
      'logoImage': logoImage,
      'logo_image': logoImage,
      'coverImage': coverImage,
      'cover_image': coverImage,
      'coverimage': coverImage, // Alias
      'image': coverImage, // Alias
      'gallery': gallery,
      'photos': gallery, // Alias for compatibility
      'foodMenuPics': foodMenuPics,
      'food_menu_pics': foodMenuPics,
      'menu_photos': foodMenuPics
          .map((url) => {'url': url})
          .toList(), // For _buildFoodMenuGallery
      'openingHours': openingHours,
      'opening_hours': openingHours,
      'instaLink': instaLink,
      'insta_link': instaLink,
      'facebookLink': facebookLink,
      'facebook_link': facebookLink,
      'twitterLink': twitterLink,
      'twitter_link': twitterLink,
      'googleMapsLink': googleMapsLink,
      'google_maps_link': googleMapsLink,
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'cost_for_two': priceRange * 500, // Estimate based on price range
      'costForTwo': priceRange * 500,
      'distance': 0, // This should come from API or calculation
      'sipzy_rating': 4.5, // This should come from API
    };
  }

  // Operator overload to allow restaurant['field'] syntax
  operator [](String key) => toMap()[key];

  // Full address string
  String get fullAddress {
    final parts = [
      address,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      area,
      city,
      state,
      pincode,
    ].where((p) => p?.isNotEmpty ?? false).toList();
    return parts.join(', ');
  }
}
