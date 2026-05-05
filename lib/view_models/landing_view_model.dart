import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --------------------------------------------------------------------------
/// LandingViewModel
/// --------------------------------------------------------------------------
/// Manages the "first launch" state using [SharedPreferences].
///
/// Design rationale:
///   - The landing / onboarding page should only appear on the first
///     launch after installation.  Subsequent launches skip it and go
///     directly to the login or home screen.
///   - A simple boolean flag (has_launched) persisted in
///     SharedPreferences is sufficient for this behaviour.
///   - The ViewModel exposes [isFirstLaunch] and an [isLoading] flag
///     so the _AuthGate widget can gate correctly without flashing
///     the wrong screen during async initialisation.
/// --------------------------------------------------------------------------
class LandingViewModel extends ChangeNotifier {
  static const String _prefsKey = 'has_launched';
  bool _isFirstLaunch = true;
  bool _isLoading = true;
  LandingViewModel() {
    _init();
  }

  /// Reads the persisted flag asynchronously on construction.
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = !(prefs.getBool(_prefsKey) ?? false);
    _isLoading = false;
    notifyListeners();
  }

  // ---- Public getters -----------------------------------------------------
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoading => _isLoading;

  /// Call this after the user finishes the landing experience (e.g.
  /// taps "Get Started").  Persists the flag so the landing page never
  /// shows again.
  Future<void> completeLanding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    _isFirstLaunch = false;
    notifyListeners();
  }
}
