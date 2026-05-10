import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  static const int maxImageSizeKB = 300; // Max 300KB per image
  static const int maxImageCount = 3;    // Max 3 images per listing
  static const int imageQuality = 70;     // 70% quality for good balance
  
  // Memory cache for images to avoid repeated decoding
  static final Map<String, ImageProvider> _imageCache = {};

  /// Pick multiple images from gallery
  Future<List<XFile>> pickImages({int maxCount = 3}) async {
    final List<XFile> images = [];
    final pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: imageQuality,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    images.addAll(pickedFiles.take(maxCount));
    
    if (kDebugMode) {
      debugPrint('📸 Picked ${images.length} images');
      for (var img in images) {
        final size = await getImageSizeKB(img);
        debugPrint('   - ${img.name}: ${size.toStringAsFixed(1)} KB');
      }
    }

    return images;
  }

  /// Pick a single image
  Future<XFile?> pickSingleImage({ImageSource source = ImageSource.gallery}) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (kDebugMode && pickedFile != null) {
      final size = await getImageSizeKB(pickedFile);
      debugPrint('📸 Picked image: ${pickedFile.name} (${size.toStringAsFixed(1)} KB)');
    }
    
    return pickedFile;
  }

  /// Convert image to Base64 string
  static Future<String?> imageToBase64(XFile image) async {
    try {
      final File file = File(image.path);
      
      if (!await file.exists()) {
        debugPrint('❌ Image file does not exist: ${image.path}');
        return null;
      }
      
      final bytes = await file.readAsBytes();
      
      // Check size limit
      if (bytes.length > maxImageSizeKB * 1024) {
        debugPrint('⚠️ Image too large: ${bytes.length / 1024} KB (max ${maxImageSizeKB} KB)');
        return null;
      }
      
      // Convert to Base64
      final base64String = base64Encode(bytes);
      
      if (kDebugMode) {
        debugPrint('✅ Image converted to Base64');
        debugPrint('   Original: ${bytes.length / 1024} KB');
        debugPrint('   Base64 length: ${base64String.length} chars (${base64String.length / 1024} KB)');
      }
      
      return base64String;
    } catch (e) {
      debugPrint('❌ Error converting image to Base64: $e');
      return null;
    }
  }

  /// Convert multiple images to Base64 strings
  static Future<List<String>> imagesToBase64List(List<XFile> images) async {
    final List<String> base64Images = [];
    
    for (int i = 0; i < images.length && i < maxImageCount; i++) {
      final image = images[i];
      if (kDebugMode) {
        debugPrint('📤 Converting image ${i + 1}/${images.length}...');
      }
      
      final base64String = await imageToBase64(image);
      if (base64String != null) {
        base64Images.add(base64String);
      }
    }
    
    if (kDebugMode) {
      debugPrint('✅ Converted ${base64Images.length}/${images.length} images');
    }
    
    return base64Images;
  }

  /// Decode Base64 to Image widget (with caching)
  static Widget base64ToImage(String base64String, {
    double? width, 
    double? height, 
    BoxFit fit = BoxFit.cover,
    bool useCache = true,
  }) {
    try {
      // Check cache first
      if (useCache && _imageCache.containsKey(base64String)) {
        return Image(
          image: _imageCache[base64String]!,
          width: width,
          height: height,
          fit: fit,
        );
      }
      
      final bytes = base64Decode(base64String);
      final imageProvider = MemoryImage(bytes);
      
      // Store in cache
      if (useCache) {
        _imageCache[base64String] = imageProvider;
      }
      
      return Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error displaying Base64 image: $error');
          return _buildPlaceholder();
        },
      );
    } catch (e) {
      debugPrint('❌ Error decoding Base64: $e');
      return _buildPlaceholder();
    }
  }

  /// Decode Base64 to ImageProvider
  static ImageProvider base64ToImageProvider(String base64String) {
    try {
      if (_imageCache.containsKey(base64String)) {
        return _imageCache[base64String]!;
      }
      
      final bytes = base64Decode(base64String);
      final imageProvider = MemoryImage(bytes);
      _imageCache[base64String] = imageProvider;
      return imageProvider;
    } catch (e) {
      debugPrint('❌ Error decoding Base64 for provider: $e');
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  static Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
    );
  }

  /// Get image file size in KB
  static Future<double> getImageSizeKB(XFile image) async {
    try {
      final File file = File(image.path);
      final bytes = await file.readAsBytes();
      return bytes.length / 1024;
    } catch (e) {
      return 0;
    }
  }

  /// Clear image cache to free memory
  static void clearCache() {
    _imageCache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ Image cache cleared');
    }
  }

  /// Check if a Base64 string is valid
  static bool isValidBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get approximate size of Base64 string in KB
  static double getBase64SizeKB(String base64String) {
    return base64String.length / 1024;
  }
}