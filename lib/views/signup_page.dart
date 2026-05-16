import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/logo_widget.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/year_picker_field.dart';
import '../models/user_model.dart';
import 'landing_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'profile_completion_page.dart';

/// --------------------------------------------------------------------------
/// SignUpPage
/// --------------------------------------------------------------------------
/// Allows new users to create an account via:
///   1. Email + password (Firebase Auth) — with a display name field
///   2. Google Sign-In (OAuth)
///
/// After successful registration, extended profile information is collected:
///   - User type (Student vs Non-Student)
///   - For Students: Course (searchable dropdown) and Year Level
///   - For Non-Students: Community Role (Local Resident/Business/Alumni)
///   - Community Since (year joined)
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
  final _displayNameController = TextEditingController(); // NEW

  // Extended profile fields
  String? _selectedUserType;
  String? _selectedCourse;
  String? _selectedYearLevel;
  String? _selectedCommunityRole;
  int? _communitySince;

  // Validation error states
  String? _userTypeError;
  String? _courseError;
  String? _yearLevelError;
  String? _communityRoleError;
  String? _communitySinceError;

  bool _isHoveringLogin = false;
  bool _isHoveringBack = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  bool get _isStudentSelected => _selectedUserType == UserTypes.student;
  bool get _isNonStudentSelected => _selectedUserType == UserTypes.nonStudent;

  void _setUserType(String? value) {
    setState(() {
      _selectedUserType = value;
      _userTypeError = null;
      if (value == UserTypes.student) {
        _selectedCommunityRole = null;
        _communityRoleError = null;
      } else if (value == UserTypes.nonStudent) {
        _selectedCourse = null;
        _selectedYearLevel = null;
        _courseError = null;
        _yearLevelError = null;
      }
    });
  }

  void _setCourse(String? value) {
    setState(() {
      _selectedCourse = value;
      _courseError = null;
    });
  }

  void _setYearLevel(String? value) {
    setState(() {
      _selectedYearLevel = value;
      _yearLevelError = null;
    });
  }

  void _setCommunityRole(String? value) {
    setState(() {
      _selectedCommunityRole = value;
      _communityRoleError = null;
    });
  }

  void _setCommunitySince(int? value) {
    setState(() {
      _communitySince = value;
      _communitySinceError = null;
    });
  }

  bool _validateExtendedFields() {
    bool isValid = true;

    if (_selectedUserType == null) {
      setState(() => _userTypeError = 'Please select whether you are a student');
      isValid = false;
    }

    if (_selectedUserType == UserTypes.student) {
      if (_selectedCourse == null || _selectedCourse!.isEmpty) {
        setState(() => _courseError = 'Please select your course');
        isValid = false;
      }
      if (_selectedYearLevel == null || _selectedYearLevel!.isEmpty) {
        setState(() => _yearLevelError = 'Please select your year level');
        isValid = false;
      }
    }

    if (_selectedUserType == UserTypes.nonStudent) {
      if (_selectedCommunityRole == null || _selectedCommunityRole!.isEmpty) {
        setState(() => _communityRoleError = 'Please select your community role');
        isValid = false;
      }
    }

    final currentYear = DateTime.now().year;
    if (_communitySince == null) {
      setState(() => _communitySinceError = 'Please enter when you joined the community');
      isValid = false;
    } else if (_communitySince! < 1950 || _communitySince! > currentYear) {
      setState(() => _communitySinceError = 'Please enter a valid year (1950-$currentYear)');
      isValid = false;
    }

    return isValid;
  }

  void _clearAllErrors() {
    setState(() {
      _userTypeError = null;
      _courseError = null;
      _yearLevelError = null;
      _communityRoleError = null;
      _communitySinceError = null;
    });
  }

  Future<void> _handleEmailSignUp() async {
    _clearAllErrors();

    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    if (!_validateExtendedFields()) return;

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signUpWithEmailPassword(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
      userType: _selectedUserType,
      course: _selectedCourse,
      yearLevel: _selectedYearLevel,
      communityRole: _selectedCommunityRole,
      communitySince: _communitySince,
    );

    if (success && mounted) {
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else if (mounted && authVM.errorMessage != null) {
      _showError(authVM.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    _clearAllErrors();

    if (!_agreedToTerms) {
      _showError('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final success = await authVM.signInWithGoogle();

    if (!success && mounted && authVM.errorMessage != null) {
      _showError(authVM.errorMessage!);
      return;
    }

    if (success && mounted) {
      if (authVM.needsProfileCompletion) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileCompletionPage()),
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.pagePadding,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogoWidget(size: 100),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 24),

                  // Email field
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address.';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password field
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

                  // Confirm Password field
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    isPassword: true,
                    isPasswordVisible: _confirmPasswordVisible,
                    onTogglePassword: () {
                      setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
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
                  const SizedBox(height: 20),

                  // Display Name field (NEW)
                  AuthTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    hint: 'How others will see you (e.g., John D.)',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a display name.';
                      }
                      if (value.trim().length < 2) {
                        return 'Display name must be at least 2 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    'Tell us about yourself',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This information helps us personalize your experience',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  _buildUserTypeSelector(),
                  if (_userTypeError != null) ...[
                    const SizedBox(height: 4),
                    Text(_userTypeError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                  ],
                  const SizedBox(height: 16),

                  if (_isStudentSelected) ...[
                    _buildCourseField(),
                    if (_courseError != null) ...[
                      const SizedBox(height: 4),
                      Text(_courseError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                    ],
                    const SizedBox(height: 16),
                    _buildYearLevelField(),
                    if (_yearLevelError != null) ...[
                      const SizedBox(height: 4),
                      Text(_yearLevelError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                    ],
                  ],

                  if (_isNonStudentSelected) ...[
                    _buildCommunityRoleField(),
                    if (_communityRoleError != null) ...[
                      const SizedBox(height: 4),
                      Text(_communityRoleError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                    ],
                  ],

                  const SizedBox(height: 16),
                  _buildCommunitySinceField(),
                  if (_communitySinceError != null) ...[
                    const SizedBox(height: 4),
                    Text(_communitySinceError!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                  ],

                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: authVM.isLoading ? null : _handleEmailSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: authVM.isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: authVM.isLoading ? null : _handleGoogleSignUp,
                    icon: const _GoogleIcon(),
                    label: const Text('Continue with Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? '),
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringLogin = true),
                        onExit: (_) => setState(() => _isHoveringLogin = false),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
                          },
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: _isHoveringLogin ? TextDecoration.underline : TextDecoration.none,
                              decorationThickness: 2.0,
                            ),
                            child: const Text('Login'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringBack = true),
                    onExit: (_) => setState(() => _isHoveringBack = false),
                    cursor: SystemMouseCursors.click,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LandingPage()),
                          (_) => false,
                        );
                      },
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          decoration: _isHoveringBack ? TextDecoration.underline : TextDecoration.none,
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

  // ------------------------------------------------------------------------
  // All helper methods are written in full (no placeholders)
  // ------------------------------------------------------------------------

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I am a...',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeOption(
                title: 'Student',
                subtitle: 'Currently enrolled',
                icon: Icons.school_outlined,
                isSelected: _isStudentSelected,
                onTap: () => _setUserType(UserTypes.student),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUserTypeOption(
                title: 'Non-Student',
                subtitle: 'Resident / Business / Alumni',
                icon: Icons.business_outlined,
                isSelected: _isNonStudentSelected,
                onTap: () => _setUserType(UserTypes.nonStudent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : Colors.black87)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.primary : AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseField() {
    return SearchableDropdown<String>(
      items: Courses.all,
      value: _selectedCourse,
      hint: 'Select your course',
      label: 'Course / Program',
      displayValue: (course) => course,
      onChanged: _setCourse,
      isRequired: true,
      errorText: _courseError,
    );
  }

  Widget _buildYearLevelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Year Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _yearLevelError != null ? Colors.red.shade300 : Colors.grey.shade300, width: 1.5),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedYearLevel,
            hint: const Text('Select year level', style: TextStyle(color: Colors.grey)),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            onChanged: _setYearLevel,
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            items: YearLevels.all.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(YearLevels.getDisplayName(level), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityRoleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Community Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: CommunityRoles.all.map((role) {
            final isSelected = _selectedCommunityRole == role;
            return GestureDetector(
              onTap: () => _setCommunityRole(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: 1.5),
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8)] : [],
                ),
                child: Text(
                  CommunityRoles.getDisplayName(role),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommunitySinceField() {
    return YearPickerField(
      value: _communitySince,
      label: 'Member since',
      hint: 'Enter year (e.g., 2024)',
      onChanged: _setCommunitySince,
      isRequired: true,
      errorText: _communitySinceError,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
            activeColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(text: 'Terms of Service', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                const TextSpan(text: ' and '),
                TextSpan(text: 'Privacy Policy', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/google.png', width: 20, height: 20, fit: BoxFit.contain);
  }
}