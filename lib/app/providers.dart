import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/auth/data/api_auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return ApiAuthRepository(apiClient);
});

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  FutureOr<AppUser?> build() {
    return null;
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();

    try {
      final authRepository = ref.read(authRepositoryProvider);

      final session = await authRepository.login(email.trim(), password);

      state = AsyncData(session.user);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  void logout() {
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);
