import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CloudinaryService {
  static String? _cloudName;
  static String? _uploadPreset;
  static bool _isInitialized = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  
  /// Initialize Cloudinary with environment variables
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    
    if (kDebugMode) {
      print('🔍 Cloudinary Debug:');
      print('   Cloud Name: ${_cloudName ?? "NOT FOUND"}');
      print('   Upload Preset: ${_uploadPreset ?? "NOT FOUND"}');
    }
    
    if (_cloudName == null || _cloudName!.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: Cloudinary cloud name not found in .env file');
        print('Please ensure .env file contains:');
        print('CLOUDINARY_CLOUD_NAME=your_cloud_name');
      }
      return;
    }
    
    if (_uploadPreset == null || _uploadPreset!.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: Cloudinary upload preset not found in .env file');
        print('Please ensure .env file contains:');
        print('CLOUDINARY_UPLOAD_PRESET=your_upload_preset');
      }
      return;
    }
    
    _isInitialized = true;
    
    if (kDebugMode) {
      print('✅ Cloudinary initialized successfully!');
      print('   Cloud Name: $_cloudName');
      print('   Upload Preset: $_uploadPreset');
    }
  }
  
  /// Check if Cloudinary is properly configured
  static bool get isConfigured => _isInitialized && _cloudName != null && _uploadPreset != null;
  
  /// Pick multiple images from gallery
  Future<List<XFile>> pickImages({int maxCount = 5}) async {
    final List<XFile> images = [];
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFiles != null) {
      images.addAll(pickedFiles.take(maxCount));
      if (kDebugMode) {
        print('📸 Picked ${images.length} images');
      }
    }

    return images;
  }
  
  /// Pick a single image from gallery or camera
  Future<XFile?> pickSingleImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    
    if (kDebugMode && pickedFile != null) {
      print('📸 Picked single image: ${pickedFile.path}');
    }
    
    return pickedFile;
  }
  
  /// Upload a single image to Cloudinary using unsigned upload
  Future<String?> uploadImage({
    required XFile image,
    required String folder,
  }) async {
    if (!isConfigured) {
      if (kDebugMode) {
        print('❌ Cloudinary not configured. Please check your .env file');
        print('   Cloud Name: $_cloudName');
        print('   Upload Preset: $_uploadPreset');
      }
      return null;
    }
    
    try {
      final file = File(image.path);
      
      // Check if file exists
      if (!await file.exists()) {
        print('❌ Image file does not exist: ${image.path}');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length / 1024; // Size in KB
      
      if (kDebugMode) {
        print('📤 Uploading image:');
        print('   File size: ${fileSize.toStringAsFixed(2)} KB');
        print('   Folder: $folder');
      }
      
      // Create multipart request
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);
      
      // Add upload preset (required for unsigned uploads)
      request.fields['upload_preset'] = _uploadPreset!;
      
      // Add folder (optional but recommended)
      request.fields['folder'] = folder;
      
      // Send request with timeout
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );
      
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      
      if (response.statusCode == 200 && jsonResponse['secure_url'] != null) {
        final imageUrl = jsonResponse['secure_url'];
        if (kDebugMode) {
          print('✅ Image uploaded successfully!');
          print('   URL: $imageUrl');
        }
        return imageUrl;
      } else {
        if (kDebugMode) {
          print('❌ Cloudinary upload failed:');
          print('   Status code: ${response.statusCode}');
          print('   Error: ${jsonResponse['error']?['message'] ?? jsonResponse}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading to Cloudinary: $e');
      }
      return null;
    }
  }
  
  /// Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleImages({
    required List<XFile> images,
    required String folder,
    String? listingId,
  }) async {
    if (!isConfigured) {
      print('❌ Cannot upload multiple images: Cloudinary not configured');
      return [];
    }
    
    final List<String> imageUrls = [];
    int successCount = 0;
    
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      if (kDebugMode) {
        print('📤 Uploading image ${i + 1}/${images.length}...');
      }
      
      final imageUrl = await uploadImage(
        image: image,
        folder: '$folder/${listingId ?? DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (imageUrl != null) {
        imageUrls.add(imageUrl);
        successCount++;
      }
    }
    
    if (kDebugMode) {
      print('✅ Upload complete: $successCount/${images.length} images uploaded');
    }
    
    return imageUrls;
  }
  
  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(String url, {int width = 500, int height = 500}) {
    if (url.contains('cloudinary.com')) {
      // Insert transformation parameters
      final uri = Uri.parse(url);
      final path = uri.path;
      final pathWithoutVersion = path.replaceFirst(RegExp(r'/v\d+/'), '/');
      final baseUrl = '${uri.scheme}://${uri.host}';
      return '$baseUrl/c_scale,w_$width,h_$height$pathWithoutVersion';
    }
    return url;
  }
  
  /// Get thumbnail URL
  String getThumbnailUrl(String url) {
    return getOptimizedImageUrl(url, width: 200, height: 200);
  }
}