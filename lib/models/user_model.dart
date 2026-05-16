/// --------------------------------------------------------------------------
/// UserModel
/// --------------------------------------------------------------------------
/// A lightweight, immutable data class that represents an authenticated
/// user within the UPamakal domain.
/// --------------------------------------------------------------------------
class UserModel {
  /// Firebase Auth UID — stable across sessions.
  final String uid;

  /// User's email address (nullable for phone-only or anonymous auth).
  final String? email;

  /// Display name, often populated by Google Sign-In.
  final String? displayName;

  /// Profile photo URL, often populated by Google Sign-In.
  final String? photoURL;

  /// Whether the email has been verified.
  final bool emailVerified;

  /// FCM token for push notifications.
  final String? fcmToken;

  /// Timestamp of when the Firestore document was first created.
  final DateTime? createdAt;

  /// List of item IDs the user has saved as favourites.
  final List<String> favorites;
  
  /// User type: 'student' or 'non_student'
  final String? userType;
  
  /// For students: their course/program
  final String? course;
  
  /// For students: their year level (I, II, III, IV, V)
  final String? yearLevel;
  
  /// For non-students: 'local_resident', 'local_business', or 'alumni'
  final String? communityRole;
  
  /// When they joined the community (year only, e.g., 2024)
  final int? communitySince;
  
  /// NEW: When profile was completed (null if never completed)
  final DateTime? profileCompletedAt;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.fcmToken,
    this.createdAt,
    this.favorites = const [],
    this.userType,
    this.course,
    this.yearLevel,
    this.communityRole,
    this.communitySince,
    this.profileCompletedAt,
  });

  // ---- Factory constructors -----------------------------------------------

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid as String,
      email: firebaseUser.email as String?,
      displayName: firebaseUser.displayName as String?,
      photoURL: firebaseUser.photoURL as String?,
      emailVerified: (firebaseUser.emailVerified as bool?) ?? false,
    );
  }

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    DateTime? createdAt;
    final raw = data['createdAt'];
    if (raw != null) {
      try {
        createdAt = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        createdAt = null;
      }
    }

    DateTime? profileCompletedAt;
    final rawCompleted = data['profileCompletedAt'];
    if (rawCompleted != null) {
      try {
        profileCompletedAt = (rawCompleted as dynamic).toDate() as DateTime;
      } catch (_) {
        profileCompletedAt = null;
      }
    }

    List<String> favorites = [];
    final rawFavs = data['favorites'];
    if (rawFavs is List) {
      favorites = List<String>.from(rawFavs);
    }

    return UserModel(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      fcmToken: data['fcmToken'] as String?,
      createdAt: createdAt,
      favorites: favorites,
      userType: data['userType'] as String?,
      course: data['course'] as String?,
      yearLevel: data['yearLevel'] as String?,
      communityRole: data['communityRole'] as String?,
      communitySince: data['communitySince'] as int?,
      profileCompletedAt: profileCompletedAt,
    );
  }

  // ---- Serialisation ------------------------------------------------------

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (userType != null) 'userType': userType,
      if (course != null) 'course': course,
      if (yearLevel != null) 'yearLevel': yearLevel,
      if (communityRole != null) 'communityRole': communityRole,
      if (communitySince != null) 'communitySince': communitySince,
      if (profileCompletedAt != null) 'profileCompletedAt': profileCompletedAt,
    };
  }

  // ---- Convenience helpers ------------------------------------------------

  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  bool isFavorite(String itemId) => favorites.contains(itemId);
  
  String getDisplayIdentifier() {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'User';
  }
  
  String getFormattedMemberSince() {
    if (communitySince == null) return 'Member since 2024';
    return 'Member since $communitySince';
  }
  
  String getAcademicInfo() {
    if (userType != 'student') return '';
    if (course == null && yearLevel == null) return '';
    if (course != null && yearLevel != null) {
      return '$course • Year $yearLevel';
    }
    if (course != null) return course!;
    if (yearLevel != null) return '$yearLevel Year';
    return '';
  }
  
  String getCommunityRoleDisplay() {
    switch (communityRole) {
      case 'local_resident':
        return 'Local Resident';
      case 'local_business':
        return 'Local Business';
      case 'alumni':
        return 'Alumni';
      default:
        return '';
    }
  }

  bool get hasCompleteProfile => userType != null && profileCompletedAt != null;

  // ---- copyWith -----------------------------------------------------------

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    String? fcmToken,
    DateTime? createdAt,
    List<String>? favorites,
    String? userType,
    String? course,
    String? yearLevel,
    String? communityRole,
    int? communitySince,
    DateTime? profileCompletedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      favorites: favorites ?? this.favorites,
      userType: userType ?? this.userType,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      communityRole: communityRole ?? this.communityRole,
      communitySince: communitySince ?? this.communitySince,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, displayName: $displayName, '
      'userType: $userType, communitySince: $communitySince, '
      'profileCompletedAt: $profileCompletedAt)';
}

/// --------------------------------------------------------------------------
/// UserType Constants
/// --------------------------------------------------------------------------
class UserTypes {
  static const String student = 'student';
  static const String nonStudent = 'non_student';
  
  static const List<String> all = [student, nonStudent];
  
  static String getDisplayName(String type) {
    switch (type) {
      case student:
        return 'Student';
      case nonStudent:
        return 'Non-Student';
      default:
        return type;
    }
  }
}

/// --------------------------------------------------------------------------
/// CommunityRole Constants
/// --------------------------------------------------------------------------
class CommunityRoles {
  static const String localResident = 'local_resident';
  static const String localBusiness = 'local_business';
  static const String alumni = 'alumni';
  
  static const List<String> all = [localResident, localBusiness, alumni];
  
  static String getDisplayName(String role) {
    switch (role) {
      case localResident:
        return 'Local Resident';
      case localBusiness:
        return 'Local Business';
      case alumni:
        return 'Alumni';
      default:
        return role;
    }
  }
}

/// --------------------------------------------------------------------------
/// Course Constants
/// --------------------------------------------------------------------------
class Courses {
  static const List<String> all = [
    'BA in Community Development',
    'BA in History',
    'BA in Sociology',
    'BA in Communication and Media Studies',
    'BA in Literature',
    'BA in Political Science',
    'BA in Psychology',
    'BS in Biology',
    'BS Accountancy',
    'BS Applied Mathematics',
    'BS Business Administration (Marketing)',
    'BS Chemical Engineering',
    'BS Chemistry',
    'BS Computer Science',
    'BS Economics',
    'BS Fisheries',
    'BS Food Technology',
    'BS Management',
    'BS Public Health',
    'BS Statistics',
  ];
  
  static List<String> get suggestions => all;
}

/// --------------------------------------------------------------------------
/// YearLevel Constants
/// --------------------------------------------------------------------------
class YearLevels {
  static const List<String> all = [
    'I',
    'II',
    'III',
    'IV',
    'V',
  ];
  
  static String getDisplayName(String level) {
    switch (level) {
      case 'I':
        return 'First Year';
      case 'II':
        return 'Second Year';
      case 'III':
        return 'Third Year';
      case 'IV':
        return 'Fourth Year';
      case 'V':
        return 'Fifth Year';
      default:
        return '$level Year';
    }
  }
}