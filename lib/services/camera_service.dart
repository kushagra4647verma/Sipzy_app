// lib/services/camera_service.dart
// ✅ FIXED: Complete camera and gallery integration with Supabase storage
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

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

  /// Upload photo to Supabase Storage
  Future<String?> uploadToSupabase(
    File file, {
    required String bucket,
    required String path,
  }) async {
    try {
      print('📤 Uploading to Supabase: $bucket/$path');

      // Ensure bucket exists (will not throw error if it already exists)
      try {
        await _supabase.storage.createBucket(bucket);
        print('✅ Bucket created/verified: $bucket');
      } catch (e) {
        print('ℹ️ Bucket already exists or error: $e');
      }

      final bytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last.toLowerCase();

      // Map file extension to MIME type
      final mimeType = _getMimeType(fileExt);

      await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final url = _supabase.storage.from(bucket).getPublicUrl(path);

      print('✅ Upload successful: $url');
      return url;
    } catch (e) {
      print('❌ Upload error: $e');
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
