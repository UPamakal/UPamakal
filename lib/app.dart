import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/landing_view_model.dart';
import 'views/landing_page.dart';
import 'views/login_page.dart';
import 'views/home_page.dart';
import 'views/profile_completion_page.dart';

/// --------------------------------------------------------------------------
/// ROOT WIDGET — UpamakalApp
/// --------------------------------------------------------------------------
/// Wraps the entire application in a [MaterialApp] with the Maroon theme.
///
/// Auth routing logic:
///   1. First launch → show LandingPage
///   2. Not first launch + authenticated + profile complete → HomePage
///   3. Not first launch + authenticated + profile incomplete → ProfileCompletionPage
///   4. Not first launch + not authenticated → LoginPage
/// --------------------------------------------------------------------------
class UpamakalApp extends StatelessWidget {
  const UpamakalApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
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
      home: const _AuthGate(),
    );
  }
}

/// --------------------------------------------------------------------------
/// _AuthGate
/// --------------------------------------------------------------------------
/// Reactive gate widget that decides which screen to show based on:
///   - LandingViewModel.isFirstLaunch (SharedPreferences)
///   - AuthViewModel.user (Firebase auth)
///   - AuthViewModel.user.userType (profile completion status)
/// --------------------------------------------------------------------------
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final landingVM = context.watch<LandingViewModel>();
    final authVM = context.watch<AuthViewModel>();
    
    // Still determining first-launch status
    if (landingVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // First launch → show branding/landing page
    if (landingVM.isFirstLaunch) {
      return const LandingPage();
    }
    
    // Not authenticated → login page
    if (!authVM.isAuthenticated) {
      return const LoginPage();
    }
    
    // User is authenticated. Check if profile is complete.
    final user = authVM.user;
    final hasCompleteProfile = user?.userType != null;
    
    // Force profile completion if userType is missing
    if (!hasCompleteProfile) {
      debugPrint('🔐 AuthGate: User ${user?.uid} has incomplete profile → redirecting to ProfileCompletionPage');
      return const ProfileCompletionPage();
    }
    
    // Fully authenticated with complete profile → home page
    debugPrint('🏠 AuthGate: User ${user?.uid} has complete profile (${user?.userType}) → HomePage');
    return const HomePage();
  }
}