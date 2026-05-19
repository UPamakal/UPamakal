import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository;

  UserService({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  Stream<List<UserModel>> searchUsers(String query) {
    return _userRepository.getAllUsers().asStream().map((users) {
      if (query.trim().isEmpty) return users;

      final lowerQuery = query.trim().toLowerCase();
      return users.where((user) {
        final name = user.displayName?.toLowerCase() ?? '';
        final email = user.email?.toLowerCase() ?? '';
        return name.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    });
  }
}
