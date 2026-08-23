import 'app_user.dart';

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;
}

abstract interface class AuthRepository {
  Future<AuthSession> login(String email, String password);
}
