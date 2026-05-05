import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/logo_widget.dart';
import '../widgets/auth_text_field.dart';
import 'landing_page.dart';
import 'login_page.dart';

/// --------------------------------------------------------------------------
/// ForgotPasswordPage
/// --------------------------------------------------------------------------
/// Provides a focused form where the user enters their email address and
/// receives a password reset link via Firebase Auth.
///
/// After the reset email is sent successfully, a confirmation message is
/// displayed and the user is offered a direct link back to the [LoginPage].
/// --------------------------------------------------------------------------
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validates the email and sends a password reset link.
  Future<void> _handleResetRequest() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    final success = await authVM.sendPasswordResetEmail(
      email: _emailController.text,
    );
    if (success && mounted) {
      setState(() => _emailSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset link sent! Check your inbox.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? 'Failed to send reset email.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  // ---- Logo -----------------------------------------------
                  const LogoWidget(size: 64),
                  const SizedBox(height: 24),
                  // ---- Title ----------------------------------------------
                  Text(
                    'Forgot Password',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // ---- Instructional text ---------------------------------
                  Text(
                    _emailSent
                        ? 'If an account exists for the email you entered, '
                              'a password reset link has been sent. Please check '
                              'your inbox and spam folder.'
                        : 'Enter your email address and well send you a '
                              'link to reset your password.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.sectionSpacing + 4),
                  // ---- Email field ----------------------------------------
                  if (!_emailSent)
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
                  if (!_emailSent) const SizedBox(height: 24),
                  // ---- Submit / Resend button -----------------------------
                  ElevatedButton(
                    onPressed: authVM.isLoading
                        ? null
                        : (_emailSent
                              ? _handleResetRequest
                              : _handleResetRequest),
                    child: authVM.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _emailSent
                                ? 'Resend Reset Link'
                                : 'Request Password Reset',
                          ),
                  ),
                  // ---- Extra actions --------------------------------------
                  const SizedBox(height: 20),
                  // ---- Back to login link (always visible) ----------------
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // ---- Back to home page ----------------------------------
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
