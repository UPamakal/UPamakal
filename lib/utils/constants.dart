import 'package:flutter/material.dart';

/// --------------------------------------------------------------------------
/// AppConstants
/// --------------------------------------------------------------------------
/// Centralised repository for all application-wide constants: colours,
/// strings, dimension tokens, and asset paths.  Editing values here
/// propagates changes everywhere consistently.
/// --------------------------------------------------------------------------
class AppConstants {
  AppConstants._(); // prevent instantiation
  // ---- Brand --------------------------------------------------------------
  static const String appName = 'UPamakal';
  static const String tagline = 'Your Campus, Your Marketplace';
  // ---- Asset paths --------------------------------------------------------
  static const String logoAssetPath = 'assets/images/UPamakal.png';
  // ---- Spacing & sizing ---------------------------------------------------
  static const double pagePadding = 24.0;
  static const double sectionSpacing = 20.0;
  static const double logoSize = 100.0;
}

/// --------------------------------------------------------------------------
/// AppColors
/// --------------------------------------------------------------------------
/// Semantic colour constants.  Primary is Maroon (#800000) as specified.
/// All other colours derive from or complement the primary while
/// maintaining sufficient contrast for accessibility.
/// --------------------------------------------------------------------------
class AppColors {
  AppColors._();

  /// Primary brand colour — Maroon
  static const Color primary = Color(0xFF800000);

  /// Slightly darker variant for pressed / hover states
  static const Color primaryDark = Color(0xFF5C0000);

  /// Light maroon tint for subtle backgrounds or highlights
  static const Color primaryLight = Color(0xFFFFF0F0);

  /// Scaffold / page background
  static const Color background = Color(0xFFFAFAFA);

  /// Muted grey for secondary text
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Standard white surface colour
  static const Color surface = Colors.white;

  /// Google brand blue — used for the Google Sign-In button
  static const Color googleBlue = Color(0xFF4285F4);
}
