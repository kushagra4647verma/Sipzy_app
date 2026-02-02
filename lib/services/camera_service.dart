// lib/services/camera_service.dart
// ✅ FIXED: Complete camera and gallery integration with Supabase storage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Compress image to reduce file size
Future<File?> compressImage(File file) async {
  try {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.path,
      'compressed_${path.basename(file.path)}',
    );

    print('🗜️ Compressing image: ${file.path}');
    print('📦 Original size: ${await file.length()} bytes');

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // ✅ 70% quality
      minWidth: 1024, // ✅ Max width
      minHeight: 1024, // ✅ Max height
    );

    if (result == null) {
      print('❌ Compression failed');
      return null;
    }

    final compressed = File(result.path);
    print('✅ Compressed size: ${await compressed.length()} bytes');
    return compressed;
  } catch (e) {
    print('❌ Compression error: $e');
    return null;
  }
}

class CameraService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  /// Check camera permission
  Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check photo library permission (iOS)
  Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Request photo library permission
  Future<bool> requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Take a photo using camera
  Future<File?> takePhoto() async {
    try {
      // Check permission
      bool hasPermission = await hasCameraPermission();
      if (!hasPermission) {
        hasPermission = await requestCameraPermission();
        if (!hasPermission) {
          print('⚠️ Camera permission denied');
          return null;
        }
      }

      // Take photo
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        print('ℹ️ User cancelled camera');
        return null;
      }

      print('✅ Photo captured: ${photo.path}');
      return File(photo.path);
    } catch (e) {
      print('❌ Error taking photo: $e');
      return null;
    }
  }

  /// Pick photo from gallery
  Future<File?> pickFromGallery() async {
    try {
      // Check permission
      bool hasPermission = await hasPhotoPermission();
      if (!hasPermission) {
        hasPermission = await requestPhotoPermission();
        if (!hasPermission) {
          print('⚠️ Photo library permission denied');
          return null;
        }
      }

      // Pick image
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        print('ℹ️ User cancelled gallery picker');
        return null;
      }

      print('✅ Photo selected from gallery: ${image.path}');
      return File(image.path);
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Show photo source selection (Camera or Gallery)
  Future<File?> showPhotoSourceDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Add Photo', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFF5B642)),
              title:
                  const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFF5B642)),
              title:
                  const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return null;

    if (result == 'camera') {
      return await takePhoto();
    } else {
      return await pickFromGallery();
    }
  }

  /// Upload photo to Supabase Storage with proper error handling
  Future<String?> uploadToSupabase(
    File file, {
    required String bucket,
    required String path,
  }) async {
    try {
      print('📤 Uploading to Supabase: $bucket/$path');

      // ✅ Read file as bytes
      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last.toLowerCase();
      final mimeType = _getMimeType(fileExt);

      print('📦 File size: ${bytes.length} bytes');
      print('📦 MIME type: $mimeType');

      // ✅ Ensure user is authenticated
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return null;
      }

      print('✅ Authenticated user: ${user.id}');

      // ✅ Upload with proper options
      await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      // ✅ Get public URL
      final url = _supabase.storage.from(bucket).getPublicUrl(path);

      print('✅ Upload successful: $url');
      return url;
    } on StorageException catch (e) {
      print('❌ Storage error: ${e.message} (${e.statusCode})');
      print('Error details: ${e.error}');
      return null;
    } catch (e, stackTrace) {
      print('❌ Upload error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Complete flow: Pick photo and upload
  Future<String?> pickAndUpload({
    required BuildContext context,
    required String bucket,
    required String folder,
    String? filename,
    Function(String)? onProgress,
  }) async {
    try {
      // Show loading indicator
      if (onProgress != null) {
        onProgress('Selecting photo...');
      }

      // Show source selection
      final file = await showPhotoSourceDialog(context);
      if (file == null) {
        print('ℹ️ No photo selected');
        return null;
      }

      if (onProgress != null) {
        onProgress('Uploading...');
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(file.path).toLowerCase().replaceAll('.', '');
      final uploadPath = '$folder/${filename ?? timestamp}.$ext';

      // Upload
      final url =
          await uploadToSupabase(file, bucket: bucket, path: uploadPath);

      if (onProgress != null && url != null) {
        onProgress('Upload complete!');
      }

      return url;
    } catch (e) {
      print('❌ pickAndUpload error: $e');
      return null;
    }
  }
}
