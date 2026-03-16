// PATH: lib/modules/auth/controller/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial());

  /// Login user
  Future<void> login(String email, String password) async {
    state = AuthLoading();
    
    try {
      final result = await _authRepository.login(email, password);
      final user = result['user'] as User;
      final token = result['token'] as String;
      
      state = Authenticated(user: user, token: token);
    } catch (e) {
      state = Unauthenticated(errorMessage: e.toString());
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = AuthLoading();
    
    try {
      await _authRepository.logout();
      state = Unauthenticated();
    } catch (e) {
      // Even if logout fails on server, clear local state
      state = Unauthenticated();
    }
  }

  /// Register new user (admin only)
  Future<User?> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      return await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
    } catch (e) {
      // Handle registration error
      return null;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check authentication status
  Future<void> checkAuthStatus() async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await _authRepository.getCurrentUser();
        final token = await _authRepository.getToken();
        
        if (user != null && token != null) {
          state = Authenticated(user: user, token: token);
          return;
        }
      }
      
      state = Unauthenticated();
    } catch (e) {
      state = Unauthenticated();
    }
  }

  /// Refresh token
  Future<void> refreshToken() async {
    try {
      final newToken = await _authRepository.refreshToken();
      if (newToken != null && state is Authenticated) {
        final authenticatedState = state as Authenticated;
        state = Authenticated(
          user: authenticatedState.user,
          token: newToken,
        );
      }
    } catch (e) {
      // Token refresh failed, logout user
      await logout();
    }
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

// Utility providers for easy access
final authUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is Authenticated) {
    return state.user;
  }
  return null;
});

final authTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authControllerProvider);
  if (state is Authenticated) {
    return state.token;
  }
  return null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is Authenticated;
});
