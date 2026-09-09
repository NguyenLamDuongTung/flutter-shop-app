import '../../../core/network/api_client.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'auth_storage.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._apiClient, this._authStorage);

  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  @override
  Future<AuthSession> login(String email, String password) async {
    final json = await _apiClient.post('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final token = json['token']?.toString();

    final rawUser = json['user'];

    if (token == null || token.isEmpty) {
      throw const FormatException('Server không trả về token đăng nhập.');
    }

    if (rawUser is! Map) {
      throw const FormatException(
        'Server không trả về thông tin người dùng hợp lệ.',
      );
    }

    final userJson = Map<String, dynamic>.from(rawUser);

    final session = AuthSession(token: token, user: AppUser.fromJson(userJson));

    _apiClient.token = token;

    await _authStorage.saveSession(session);

    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final session = await _authStorage.readSession();

    if (session != null) {
      _apiClient.token = session.token;
    }

    return session;
  }

  @override
  Future<void> logout() async {
    _apiClient.token = null;
    await _authStorage.clearSession();
  }
}
