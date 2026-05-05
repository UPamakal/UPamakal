import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/logo_widget.dart';
import '../widgets/auth_text_field.dart';
import 'forgot_password_page.dart';
import 'landing_page.dart';
import 'login_page.dart';

/// --------------------------------------------------------------------------
/// SignUpPage
/// --------------------------------------------------------------------------
/// Allows new users to create an account via:
///   1. Email + password (Firebase Auth)
///   2. Google Sign-In (OAuth)
///
/// After successful registration an email verification is sent
/// automatically by the [AuthService].
/// --------------------------------------------------------------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _agreedToTerms = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates the form and registers the user with email + password.
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signUpWithEmailPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (success && mounted) {
      // Show a success message and navigate back to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Account created! Please verify your email before signing in.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    } else if (mounted) {
      _showError(authVM.errorMessage ?? 'Registration failed.');
    }
  }

  /// Triggers Google Sign-In as a registration shortcut.
  Future<void> _handleGoogleSignUp() async {
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signInWithGoogle();
    if (!success && mounted) {
      _showError(authVM.errorMessage ?? 'Google sign-in failed.');
    }
    // On success, AuthGate auto-navigates to HomePage.
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
                  const LogoWidget(size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Create an Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Join your campus marketplace today',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.sectionSpacing + 4),
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
                  const SizedBox(height: 14),
                  // ---- Password field -------------------------------------
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'At least 6 characters',
                    isPassword: true,
                    isPasswordVisible: _passwordVisible,
                    onTogglePassword: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  // ---- Confirm Password field -----------------------------
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    isPassword: true,
                    isPasswordVisible: _confirmPasswordVisible,
                    onTogglePassword: () {
                      setState(
                        () =>
                            _confirmPasswordVisible = !_confirmPasswordVisible,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // ---- Terms of Service checkbox --------------------------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ---- Register button ------------------------------------
                  ElevatedButton(
                    onPressed: authVM.isLoading ? null : _handleEmailSignUp,
                    child: authVM.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Register'),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  // ---- Google Sign-Up button ------------------------------
                  OutlinedButton.icon(
                    onPressed: authVM.isLoading ? null : _handleGoogleSignUp,
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
                  const SizedBox(height: 20),
                  // ---- Forgot password link -------------------------------
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Request Password Reset',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ---- Already have account? Login link -------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ---- Back to home link ----------------------------------
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LandingPage()),
                        (_) => false,
                      );
                    },
                    child: const Text(
                      'Back to home page',
                      style: TextStyle(color: AppColors.textSecondary),
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

/// Simple Google "G" icon used in the sign-up page.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.googleBlue,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
