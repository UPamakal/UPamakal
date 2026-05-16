import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/logo_widget.dart';
import '../widgets/auth_text_field.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'landing_page.dart';
import 'profile_completion_page.dart';

/// --------------------------------------------------------------------------
/// LoginPage
/// --------------------------------------------------------------------------
/// Allows existing users to sign in via:
///   1. Email + password (Firebase Auth)
///   2. Google Sign-In (OAuth)
///
/// Links are provided for password reset and new account registration.
/// --------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isHoveringRegister = false;
  bool _isHoveringForgot = false;
  bool _isHoveringBack = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates the form and triggers email/password sign-in.
  Future<void> _handleEmailLogin() async {
    print("🔐 LOGIN BUTTON PRESSED (Email/Password)");

    if (!_formKey.currentState!.validate()) {
      print("❌ Form validation failed");
      return;
    }

    final authVM = context.read<AuthViewModel>();

    try {
      print("⏳ Attempting sign-in...");

      final success = await authVM.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print("📊 Login result: $success");

      if (!success && mounted) {
        print("❌ Login failed: ${authVM.errorMessage}");
        _showError(authVM.errorMessage ?? 'Login failed.');
      }

      if (success && mounted) {
        print("✅ Login successful - navigating to HomePage");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } catch (e) {
      print("🔥 Exception during login: $e");
      if (mounted) {
        _showError('Something went wrong during login.');
      }
    }
  }

  /// Triggers Google Sign-In.
  Future<void> _handleGoogleLogin() async {
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      if (authVM.needsProfileCompletion) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileCompletionPage()),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } else {
      _showError(authVM.errorMessage ?? 'Google sign-in failed.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Logo & branding -----------------------------------
                  const LogoWidget(size: 150),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Log in to continue',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.sectionSpacing + 8),
                  // ---- Email field ----------------------------------------
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address.';
                      }
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+.[^@\s]+$',
                      ).hasMatch(value.trim())) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // ---- Password field -------------------------------------
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    isPassword: true,
                    isPasswordVisible: _passwordVisible,
                    onTogglePassword: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // ---- Forgot password link -------------------------------
                  Align(
                    alignment: Alignment.centerRight,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHoveringForgot = true),
                      onExit: (_) => setState(() => _isHoveringForgot = false),
                      cursor: SystemMouseCursors.click,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            decoration: _isHoveringForgot
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationThickness: 2.0,
                          ),
                          child: const Text('Forgot Password'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ---- Login button ---------------------------------------
                  ElevatedButton(
                    onPressed: authVM.isLoading ? null : _handleEmailLogin,
                    child: authVM.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 20),
                  // ---- Divider with "or" ----------------------------------
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ---- Google Sign-In button ------------------------------
                  OutlinedButton.icon(
                    onPressed: authVM.isLoading ? null : _handleGoogleLogin,
                    icon: const _GoogleIcon(),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ---- Register link --------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account yet? "),
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringRegister = true),
                        onExit: (_) => setState(() => _isHoveringRegister = false),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignUpPage(),
                              ),
                            );
                          },
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: _isHoveringRegister
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                              decorationThickness: 2.0,
                            ),
                            child: const Text('Register'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ---- Back to home link ----------------------------------
                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringBack = true),
                    onExit: (_) => setState(() => _isHoveringBack = false),
                    cursor: SystemMouseCursors.click,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LandingPage()),
                        );
                      },
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          decoration: _isHoveringBack
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationThickness: 2.0,
                        ),
                        child: const Text('Back to home page'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple SVG-free Google "G" icon built with Flutter's painting API.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
    );
  }
}