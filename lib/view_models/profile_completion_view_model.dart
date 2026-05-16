import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// --------------------------------------------------------------------------
/// ProfileCompletionViewModel
/// --------------------------------------------------------------------------
/// Manages the state and logic for the profile completion screen.
/// This screen is shown to:
///   1. Google Sign-In users who are signing up for the first time
///   2. Existing users who somehow have incomplete profiles
///
/// The ViewModel handles:
///   - Form field state management
///   - Conditional validation (student vs non-student)
///   - Profile submission to AuthService
///   - Loading and error states
/// --------------------------------------------------------------------------
class ProfileCompletionViewModel extends ChangeNotifier {
  final AuthService _authService;
  final String _userId;

  // Form fields
  String? _userType;
  String? _course;
  String? _yearLevel;
  String? _communityRole;
  int? _communitySince;
  
  // UI state
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isComplete = false;
  
  // Validation error states (separate from submission error)
  String? _userTypeError;
  String? _courseError;
  String? _yearLevelError;
  String? _communityRoleError;
  String? _communitySinceError;

  ProfileCompletionViewModel({
    required AuthService authService,
    required String userId,
  })  : _authService = authService,
        _userId = userId;

  // ── Getters ─────────────────────────────────────────────────────────────

  String? get userType => _userType;
  String? get course => _course;
  String? get yearLevel => _yearLevel;
  String? get communityRole => _communityRole;
  int? get communitySince => _communitySince;
  
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isComplete => _isComplete;
  
  String? get userTypeError => _userTypeError;
  String? get courseError => _courseError;
  String? get yearLevelError => _yearLevelError;
  String? get communityRoleError => _communityRoleError;
  String? get communitySinceError => _communitySinceError;
  
  bool get isStudentSelected => _userType == UserTypes.student;
  bool get isNonStudentSelected => _userType == UserTypes.nonStudent;
  
  bool get hasValidationErrors =>
      _userTypeError != null ||
      _courseError != null ||
      _yearLevelError != null ||
      _communityRoleError != null ||
      _communitySinceError != null;
  
  bool get isFormValid {
    if (_userType == null) return false;
    
    if (_userType == UserTypes.student) {
      return _course != null && 
             _course!.isNotEmpty && 
             _yearLevel != null && 
             _yearLevel!.isNotEmpty &&
             _communitySince != null;
    }
    
    if (_userType == UserTypes.nonStudent) {
      return _communityRole != null && 
             _communityRole!.isNotEmpty && 
             _communitySince != null;
    }
    
    return false;
  }

  // ── Setters with validation clearing ────────────────────────────────────

  void setUserType(String? value) {
    _userType = value;
    _userTypeError = null;
    
    // Clear dependent fields when switching types
    if (value == UserTypes.student) {
      _communityRole = null;
      _communityRoleError = null;
    } else if (value == UserTypes.nonStudent) {
      _course = null;
      _yearLevel = null;
      _courseError = null;
      _yearLevelError = null;
    }
    
    notifyListeners();
  }

  void setCourse(String? value) {
    _course = value;
    _courseError = null;
    notifyListeners();
  }

  void setYearLevel(String? value) {
    _yearLevel = value;
    _yearLevelError = null;
    notifyListeners();
  }

  void setCommunityRole(String? value) {
    _communityRole = value;
    _communityRoleError = null;
    notifyListeners();
  }

  void setCommunitySince(int? value) {
    _communitySince = value;
    _communitySinceError = null;
    notifyListeners();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  /// Validates all form fields and sets appropriate error messages.
  /// Returns true if the form is valid, false otherwise.
  bool validateForm() {
    bool isValid = true;

    // Validate user type
    if (_userType == null) {
      _userTypeError = 'Please select whether you are a student';
      isValid = false;
    }

    // Student-specific validation
    if (_userType == UserTypes.student) {
      if (_course == null || _course!.isEmpty) {
        _courseError = 'Please select your course';
        isValid = false;
      }
      if (_yearLevel == null || _yearLevel!.isEmpty) {
        _yearLevelError = 'Please select your year level';
        isValid = false;
      }
    }

    // Non-student specific validation
    if (_userType == UserTypes.nonStudent) {
      if (_communityRole == null || _communityRole!.isEmpty) {
        _communityRoleError = 'Please select your community role';
        isValid = false;
      }
    }

    // Community since validation (required for all)
    final currentYear = DateTime.now().year;
    if (_communitySince == null) {
      _communitySinceError = 'Please enter when you joined the community';
      isValid = false;
    } else if (_communitySince! < 1950 || _communitySince! > currentYear) {
      _communitySinceError = 'Please enter a valid year (1950-$currentYear)';
      isValid = false;
    }

    notifyListeners();
    return isValid;
  }

  /// Clears all validation errors
  void clearValidationErrors() {
    _userTypeError = null;
    _courseError = null;
    _yearLevelError = null;
    _communityRoleError = null;
    _communitySinceError = null;
    notifyListeners();
  }

  /// Clears submission error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Submission ──────────────────────────────────────────────────────────

  /// Submits the completed profile to AuthService.
  /// Returns true if successful, false otherwise.
  Future<bool> saveProfile() async {
    // Clear previous errors
    clearValidationErrors();
    clearError();
    
    // Validate form
    if (!validateForm()) {
      debugPrint('❌ Profile completion validation failed');
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      debugPrint('📤 Submitting profile completion for user: $_userId');
      debugPrint('   UserType: $_userType');
      debugPrint('   Course: $_course');
      debugPrint('   YearLevel: $_yearLevel');
      debugPrint('   CommunityRole: $_communityRole');
      debugPrint('   CommunitySince: $_communitySince');

      final updatedUser = await _authService.completeProfile(
        userId: _userId,
        userType: _userType!,
        course: _course,
        yearLevel: _yearLevel,
        communityRole: _communityRole,
        communitySince: _communitySince,
      );

      debugPrint('✅ Profile completed successfully for: ${updatedUser.email}');
      
      _isComplete = true;
      _isSubmitting = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e);
      debugPrint('❌ Profile completion failed: $e');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Resets the form to initial state (useful if user wants to start over)
  void resetForm() {
    _userType = null;
    _course = null;
    _yearLevel = null;
    _communityRole = null;
    _communitySince = null;
    _userTypeError = null;
    _courseError = null;
    _yearLevelError = null;
    _communityRoleError = null;
    _communitySinceError = null;
    _errorMessage = null;
    _isComplete = false;
    notifyListeners();
  }

  // ── Helper Methods ──────────────────────────────────────────────────────

  String _parseErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    if (message.contains('permission-denied')) {
      return 'Unable to save profile. Please try again.';
    }
    if (message.contains('not-found')) {
      return 'User account not found. Please sign out and sign in again.';
    }
    
    return 'Failed to save profile. Please try again.';
  }

  @override
  String toString() {
    return 'ProfileCompletionViewModel(userId: $_userId, userType: $_userType, isValid: $isFormValid)';
  }
}