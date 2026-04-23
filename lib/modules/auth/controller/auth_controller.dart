// PATH: lib/modules/auth/controller/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

const bool _kEnableAuth = bool.fromEnvironment(
  'ENABLE_AUTH',
  defaultValue: true,
);

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial());

  User _hydrateActiveTenant(User user) {
    final storedTenantId = _authRepository.getSelectedTenantId();
    final storedTenantType = _authRepository.getSelectedTenantType();
    final storedEntityId = _authRepository.getSelectedEntityId();
    final storedTenantRouteSystemId = _authRepository
        .getSelectedTenantRouteSystemId();

    if ((storedTenantId == null || storedTenantId.isEmpty) &&
        (storedTenantType == null || storedTenantType.isEmpty)) {
      final defaultTenantId = (user.defaultBusinessBranchId?.isNotEmpty == true)
          ? user.defaultBusinessBranchId!
          : user.orgId;
      final defaultTenantType =
          (user.defaultBusinessBranchId?.isNotEmpty == true) ? 'BRANCH' : 'ORG';
      
      return user.copyWith(
        activeTenantId: defaultTenantId,
        activeTenantType: defaultTenantType,
        activeTenantRouteSystemId: user.routeSystemId,
      );
    }

    return user.copyWith(
      activeTenantId: storedTenantId,
      activeTenantType: storedTenantType,
      activeEntityId: storedEntityId,
      activeTenantRouteSystemId:
          (storedTenantRouteSystemId != null &&
              storedTenantRouteSystemId.isNotEmpty)
          ? storedTenantRouteSystemId
          : user.routeSystemId,
    );
  }

  Future<void> setActiveTenant({
    required String id,
    required String type,
    String? routeSystemId,
    String? entityId,
  }) async {
    if (state is! Authenticated) {
      return;
    }
    final authState = state as Authenticated;
    final normalizedType = type.trim().toUpperCase();
    await _authRepository.setSelectedTenant(
      id: id,
      type: normalizedType,
      routeSystemId: routeSystemId,
      entityId: entityId,
    );

    state = Authenticated(
      token: authState.token,
      user: authState.user.copyWith(
        activeTenantId: id.trim(),
        activeTenantType: normalizedType,
        activeEntityId: entityId?.trim(),
        activeTenantRouteSystemId: routeSystemId?.trim().isNotEmpty == true
            ? routeSystemId!.trim()
            : authState.user.activeTenantRouteSystemId,
      ),
    );
  }

  /// Login user
  Future<void> login(String email, String password) async {
    state = AuthLoading();

    try {
      final result = await _authRepository.login(email, password);
      final user = _hydrateActiveTenant(result['user'] as User);
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
    if (!_kEnableAuth) {
      state = Unauthenticated();
      return;
    }

    try {
      final token = _authRepository.getToken();
      if (token == null || token.isEmpty) {
        state = Unauthenticated();
        return;
      }

      final cachedUser = _authRepository.getUser();
      if (cachedUser != null) {
        state = Authenticated(
          user: _hydrateActiveTenant(cachedUser),
          token: token,
        );
      }

      var user = await _authRepository.getCurrentUser();
      if (user != null) {
        user = _hydrateActiveTenant(user);
        state = Authenticated(user: user, token: token);
        return;
      }

      // Profile call failed (expired token) — attempt refresh
      final newToken = await _authRepository.refreshToken();
      if (newToken != null) {
        user =
            await _authRepository.getCurrentUser() ?? _authRepository.getUser();
        if (user != null) {
          user = _hydrateActiveTenant(user);
          state = Authenticated(user: user, token: newToken);
          return;
        }
      }

      // Both access token and refresh token are invalid — force logout
      await _authRepository.logout().catchError((_) {});
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
        state = Authenticated(user: authenticatedState.user, token: newToken);
      }
    } catch (e) {
      // Token refresh failed, logout user
      await logout();
    }
  }

  Future<bool> requestPasswordReset(String email, {String? redirectTo}) async {
    try {
      await _authRepository.requestPasswordReset(email, redirectTo: redirectTo);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    return AuthController(authRepository: authRepository);
  },
);

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
