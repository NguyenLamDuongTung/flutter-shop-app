import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _userEmailKey = 'auth_user_email';
  static const String _displayNameKey = 'auth_display_name';

  Future<void> saveSession(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.setString(_tokenKey, session.token),
      preferences.setInt(_userIdKey, session.user.id),
      preferences.setString(_userEmailKey, session.user.email),
      preferences.setString(_displayNameKey, session.user.displayName),
    ]);
  }

  Future<AuthSession?> readSession() async {
    final preferences = await SharedPreferences.getInstance();

    final token = preferences.getString(_tokenKey);
    final userId = preferences.getInt(_userIdKey);
    final email = preferences.getString(_userEmailKey);
    final displayName = preferences.getString(_displayNameKey);

    if (token == null ||
        token.isEmpty ||
        userId == null ||
        email == null ||
        email.isEmpty) {
      return null;
    }

    return AuthSession(
      token: token,
      user: AppUser(
        id: userId,
        email: email,
        displayName: displayName ?? email,
      ),
    );
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.remove(_tokenKey),
      preferences.remove(_userIdKey),
      preferences.remove(_userEmailKey),
      preferences.remove(_displayNameKey),
    ]);
  }
}
