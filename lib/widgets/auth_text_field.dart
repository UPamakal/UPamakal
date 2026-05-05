import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// --------------------------------------------------------------------------
/// AuthTextField
/// --------------------------------------------------------------------------
/// A reusable styled text field used across Login, Sign-Up, and Forgot
/// Password pages.  Provides consistent look (Maroon focus border, clean
/// typography) and optional password visibility toggle.
/// --------------------------------------------------------------------------
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.keyboardType = TextInputType.text,
    this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Password visibility toggle (only shown for password fields)
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: onTogglePassword,
              )
            : null,
      ),
    );
  }
}
