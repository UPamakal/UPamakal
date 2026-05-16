import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/profile_completion_view_model.dart';
import '../services/auth_service.dart';
import '../widgets/logo_widget.dart';
import '../widgets/searchable_dropdown.dart';
import '../widgets/year_picker_field.dart';
import '../models/user_model.dart';
import 'home_page.dart';
import 'login_page.dart';

/// --------------------------------------------------------------------------
/// ProfileCompletionPage
/// --------------------------------------------------------------------------
/// This screen is shown to users who have authenticated (via Google Sign-In)
/// but haven't completed their profile information yet.
///
/// It collects:
///   - User type (Student vs Non-Student)
///   - For Students: Course and Year Level
///   - For Non-Students: Community Role
///   - Community Since (year joined)
///
/// After successful submission, the user is taken to the HomePage.
/// --------------------------------------------------------------------------
class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  late ProfileCompletionViewModel _viewModel;
  late String _userId;

  @override
  void initState() {
    super.initState();
    
    // Get user ID from AuthViewModel (which is already in the provider tree)
    // Use listen: false to avoid rebuilding on auth changes
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authVM.user?.uid;
    
    if (userId == null) {
      debugPrint('❌ ProfileCompletionPage: No user ID found - redirecting to login');
      // Navigate back to login after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        }
      });
      return;
    }
    
    _userId = userId;
    
    // Create AuthService directly (no need for Provider)
    final authService = AuthService();
    
    _viewModel = ProfileCompletionViewModel(
      authService: authService,
      userId: userId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await _viewModel.saveProfile();
    
    if (success && mounted) {
      context.read<AuthViewModel>().clearProfileCompletionFlag();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } else if (mounted && _viewModel.errorMessage != null) {
      // NEW: Show different message for network failures
      final isNetworkError = _viewModel.errorMessage!.contains('internet') ||
                             _viewModel.errorMessage!.contains('network');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isNetworkError ? 5 : 3),
          action: isNetworkError
              ? SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _handleSubmit(),
                  textColor: Colors.white,
                )
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If userId wasn't set, we're already navigating away
    // Show loading indicator
    if (_userId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: _viewModel.isSubmitting
                  ? null
                  : () {
                      _showExitConfirmationDialog();
                    },
            ),
            title: const Text(
              'Complete Your Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: _viewModel.isComplete
                ? _buildSuccessState()
                : _buildProfileForm(),
          ),
        );
      },
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Center(
            child: LogoWidget(size: 80),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This information helps personalize your experience\non UPamakal',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Error message (if any)
          if (_viewModel.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _viewModel.errorMessage!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _viewModel.clearError(),
                    child: Icon(Icons.close, color: Colors.red.shade700, size: 18),
                  ),
                ],
              ),
            ),

          // User Type Selection
          _buildUserTypeSelector(),
          if (_viewModel.userTypeError != null) ...[
            const SizedBox(height: 4),
            Text(
              _viewModel.userTypeError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 20),

          // Conditional Fields
          if (_viewModel.isStudentSelected) ...[
            _buildCourseField(),
            if (_viewModel.courseError != null) ...[
              const SizedBox(height: 4),
              Text(
                _viewModel.courseError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 16),
            _buildYearLevelField(),
            if (_viewModel.yearLevelError != null) ...[
              const SizedBox(height: 4),
              Text(
                _viewModel.yearLevelError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
          ],

          if (_viewModel.isNonStudentSelected) ...[
            _buildCommunityRoleField(),
            if (_viewModel.communityRoleError != null) ...[
              const SizedBox(height: 4),
              Text(
                _viewModel.communityRoleError!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
          ],

          const SizedBox(height: 16),
          _buildCommunitySinceField(),
          if (_viewModel.communitySinceError != null) ...[
            const SizedBox(height: 4),
            Text(
              _viewModel.communitySinceError!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ],

          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _viewModel.isSubmitting || !_viewModel.isFormValid
                  ? null
                  : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: _viewModel.isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Complete Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
          
          // Skip option (with warning)
          TextButton(
            onPressed: _viewModel.isSubmitting ? null : _showSkipConfirmationDialog,
            child: const Text(
              'Skip for now',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I am a...',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeCard(
                title: 'Student',
                subtitle: 'Currently enrolled',
                icon: Icons.school_outlined,
                isSelected: _viewModel.isStudentSelected,
                onTap: () => _viewModel.setUserType(UserTypes.student),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUserTypeCard(
                title: 'Non-Student',
                subtitle: 'Resident / Business / Alumni',
                icon: Icons.business_outlined,
                isSelected: _viewModel.isNonStudentSelected,
                onTap: () => _viewModel.setUserType(UserTypes.nonStudent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseField() {
    return SearchableDropdown<String>(
      items: Courses.all,
      value: _viewModel.course,
      hint: 'Select your course',
      label: 'Course / Program',
      displayValue: (course) => course,
      onChanged: _viewModel.setCourse,
      isRequired: true,
      errorText: _viewModel.courseError,
    );
  }

  Widget _buildYearLevelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Year Level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _viewModel.yearLevelError != null
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _viewModel.yearLevel,
            hint: const Text(
              'Select year level',
              style: TextStyle(color: Colors.grey),
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            onChanged: _viewModel.setYearLevel,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: YearLevels.all.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(YearLevels.getDisplayName(level)),
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
        const Text(
          'Community Role',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: CommunityRoles.all.map((role) {
            final isSelected = _viewModel.communityRole == role;
            return GestureDetector(
              onTap: () => _viewModel.setCommunityRole(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCommunityRoleIcon(role),
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CommunityRoles.getDisplayName(role),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getCommunityRoleIcon(String role) {
    switch (role) {
      case CommunityRoles.localResident:
        return Icons.home_outlined;
      case CommunityRoles.localBusiness:
        return Icons.store_outlined;
      case CommunityRoles.alumni:
        return Icons.emoji_events_outlined;
      default:
        return Icons.person_outline;
    }
  }

  Widget _buildCommunitySinceField() {
    return YearPickerField(
      value: _viewModel.communitySince,
      label: 'Member since',
      hint: 'Enter year (e.g., 2024)',
      onChanged: _viewModel.setCommunitySince,
      isRequired: true,
      errorText: _viewModel.communitySinceError,
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Profile Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your profile has been successfully updated.\nRedirecting to home page...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Profile Setup?'),
        content: const Text(
          'Your profile information will not be saved. '
          'You can complete it later from your profile page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (_) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmationDialog() {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final wasForced = authVM.wasProfileCompletionForced;
    
    String message = 'You can always complete your profile later from the Profile page. '
        'Some features may be limited until you provide this information.';
    
    if (wasForced) {
      message = 'This is your first time signing in. While you can skip for now, '
          'you\'ll be reminded to complete your profile on your next login. '
          'Some features will be limited until you provide this information.';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(wasForced ? 'Skip profile setup?' : 'Skip for now?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // NEW: If forced and skipping, mark attempt as counted
              if (wasForced) {
                // Attempt already counted in AuthService
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You can complete your profile later from Settings'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (_) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}