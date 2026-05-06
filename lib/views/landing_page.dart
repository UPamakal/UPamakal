import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../view_models/landing_view_model.dart';
import '../widgets/logo_widget.dart';
import 'login_page.dart';

/// --------------------------------------------------------------------------
/// LandingPage
/// --------------------------------------------------------------------------
/// Full-screen onboarding experience that appears only on the first
/// launch after installation.  It introduces the UPamakal brand and
/// invites the user to tap "Get Started" to proceed to authentication.
///
/// After the user taps the button, [LandingViewModel.completeLanding] is
/// called to persist the fact that onboarding has been seen, then the
/// app navigates to the [LoginPage].
/// --------------------------------------------------------------------------
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.pagePadding,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // ---- Logo (increased size on landing page) --------------
              const LogoWidget(size: 300),
              const SizedBox(height: 5),
              // ---- App name -----------------------------------------------
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              // ---- Tagline ------------------------------------------------
              Text(
                AppConstants.tagline,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // ---- Subtitle -----------------------------------------------
              Text(
                'Buy and sell within your campus community.\nSafe, fast, and exclusively for students.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // ---- Get Started button -------------------------------------
              ElevatedButton(
                onPressed: () async {
                  // Persist that onboarding is done
                  await context.read<LandingViewModel>().completeLanding();
                  // Navigate to login, replacing the landing page
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
