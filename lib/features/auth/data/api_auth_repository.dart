import '../../../core/network/api_client.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthSession> login(String email, String password) async {
    final json = await _apiClient.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final session = AuthSession(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );

    _apiClient.token = session.token;

    return session;
  }
}
