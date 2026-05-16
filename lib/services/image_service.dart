import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageService {
  final ImagePicker _imagePicker = ImagePicker();

  static const int maxImageSizeKB = 300;
  static const int maxImageCount = 3;
  static const int imageQuality = 70;

  // Cache for image analysis
  static final Map<String, _ImageColorData> _colorCache = {};
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
      for (var image in images) {
        final size = await getImageSizeKB(image);
        debugPrint('   - ${image.name}: ${size.toStringAsFixed(1)} KB');
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

      if (bytes.length > maxImageSizeKB * 1024) {
        debugPrint('⚠️ Image too large: ${bytes.length / 1024} KB (max $maxImageSizeKB KB)');
        return null;
      }

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
  static Widget base64ToImage(
    String base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool useCache = true,
  }) {
    try {
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

  /// Clear all caches
  static void clearCache() {
    _imageCache.clear();
    _colorCache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ Image and color caches cleared');
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

  // ==================== COLOR ANALYSIS ====================

  /// Analyze an image from Base64 string to extract dominant color
  static Future<_ImageColorData?> analyzeImageColor(String base64String) async {
    // Check cache first
    if (_colorCache.containsKey(base64String)) {
      return _colorCache[base64String];
    }

    try {
      final bytes = base64Decode(base64String);
      // FIX: decodeImageFromList now returns Future<ui.Image> directly (no callback)
      final uiImage = await decodeImageFromList(bytes);
      final colorData = await _extractDominantColor(uiImage);
      _colorCache[base64String] = colorData;
      return colorData;
    } catch (e) {
      debugPrint('❌ Error analyzing image color: $e');
      return null;
    }
  }

  /// Extract dominant color from ui.Image
  // FIX: marked async so toByteData() can be awaited
  static Future<_ImageColorData> _extractDominantColor(ui.Image uiImage) async {
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return _getDefaultColorData();

    // FIX: use Image.fromBytes with numChannels instead of deprecated format enum
    final image = img.Image.fromBytes(
      width: uiImage.width,
      height: uiImage.height,
      bytes: byteData.buffer,
      numChannels: 4,
    );

    // Resize for faster processing
    final smallerImage = img.copyResize(image, width: 50, height: 50);

    // Get dominant color (most frequent color, quantized to reduce noise)
    final colors = <int, int>{};
    for (final pixel in smallerImage) {
      // FIX: pixel channel values are num; cast to int before bitwise ops
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final quantized = ((r ~/ 32) << 10) | ((g ~/ 32) << 5) | (b ~/ 32);
      colors[quantized] = (colors[quantized] ?? 0) + 1;
    }

    final dominantQuantized =
        // FIX: renamed lambda parameter from 'b' to 'entry' to avoid shadowing
        //      the color component variable 'b' declared above
        colors.entries.reduce((a, entry) => a.value > entry.value ? a : entry).key;

    final r = ((dominantQuantized >> 10) & 0x1F) * 32;
    final g = ((dominantQuantized >> 5) & 0x1F) * 32;
    final b = (dominantQuantized & 0x1F) * 32;

    final dominantColor = Color.fromRGBO(r, g, b, 1.0);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    return _ImageColorData(
      dominantColor: dominantColor,
      luminance: luminance,
      needsDarkOverlay: luminance > 0.6,
      needsLightOverlay: luminance < 0.4,
    );
  }

  static _ImageColorData _getDefaultColorData() {
    return _ImageColorData(
      dominantColor: const Color(0xFF808080),
      luminance: 0.5,
      needsDarkOverlay: false,
      needsLightOverlay: false,
    );
  }

  /// Get adaptive background color for buttons based on image
  static Future<Color> getAdaptiveButtonBackground(String base64String) async {
    final colorData = await analyzeImageColor(base64String);

    if (colorData == null) {
      return Colors.black.withValues(alpha: 0.5);
    }

    if (colorData.needsDarkOverlay) {
      return Colors.black.withValues(alpha: 0.45);
    } else if (colorData.needsLightOverlay) {
      return Colors.white.withValues(alpha: 0.35);
    } else {
      return Colors.black.withValues(alpha: 0.3);
    }
  }

  /// Preload color analysis for multiple images (batch processing)
  static Future<Map<String, _ImageColorData>> preloadImageColors(
      List<String> base64Strings) async {
    final results = <String, _ImageColorData>{};

    for (final base64String in base64Strings) {
      final colorData = await analyzeImageColor(base64String);
      if (colorData != null) {
        results[base64String] = colorData;
      }
    }

    return results;
  }
}

/// Data class for image color analysis results
class _ImageColorData {
  final Color dominantColor;
  final double luminance;
  final bool needsDarkOverlay;
  final bool needsLightOverlay;

  _ImageColorData({
    required this.dominantColor,
    required this.luminance,
    required this.needsDarkOverlay,
    required this.needsLightOverlay,
  });
}