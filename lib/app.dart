import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/landing_view_model.dart';
import 'views/landing_page.dart';
import 'views/login_page.dart';
import 'views/home_page.dart';

/// --------------------------------------------------------------------------
/// ROOT WIDGET — UpamakalApp
/// --------------------------------------------------------------------------
/// Wraps the entire application in a [MaterialApp] with the Maroon theme.
///
/// Auth routing logic:
///   1. If the app is being launched for the first time, show the
///      [LandingPage] regardless of auth state (invites the user to
///      explore the brand before logging in).
///   2. If the app has been launched before AND the user is already
///      signed in (Firebase persisted session), go straight to
///      [HomePage].
///   3. Otherwise, show the [LoginPage].
///
/// This logic lives in [_AuthGate] which combines [LandingViewModel]
/// (first-launch flag) and [AuthViewModel] (Firebase auth stream).
/// --------------------------------------------------------------------------
class UpamakalApp extends StatelessWidget {
  const UpamakalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // ---- Maroon theme ---------------------------------------------------
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.black),
          actionsIconTheme: IconThemeData(color: Colors.black),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      // ---- Auth routing gate ----------------------------------------------
      home: const _AuthGate(),
    );
  }
}

/// --------------------------------------------------------------------------
/// _AuthGate
/// --------------------------------------------------------------------------
/// Reactive gate widget that decides which screen to show based on:
///   - [LandingViewModel.isFirstLaunch] — persisted in SharedPreferences
///   - [AuthViewModel.user] — driven by Firebase's auth state stream
///
/// Both are consumed via [Provider] / context watchers so the UI
/// automatically updates when state changes (e.g. user logs in/out).
/// --------------------------------------------------------------------------
class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    // Watch ViewModels — rebuild whenever they notify listeners
    final landingVM = context.watch<LandingViewModel>();
    final authVM = context.watch<AuthViewModel>();
    // Still determining first-launch status (loading SharedPreferences)
    if (landingVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // First launch → show branding/landing page
    if (landingVM.isFirstLaunch) {
      return const LandingPage();
    }
    // Not first launch + already authenticated → skip login
    if (authVM.isAuthenticated) {
      return const HomePage();
    }
    // Not first launch + not authenticated → login
    return const LoginPage();
  }
}
