import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.role,
  });

  final AuthStatus status;
  final String? role;

  bool get isLoggedIn => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState(status: AuthStatus.unknown)) {
    _bootstrap();
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    try {
      final storage = await _ref.read(tokenStorageProvider.future);
      final token = await storage.getToken();
      state = AuthState(
        status: token != null && token.isNotEmpty
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        role: 'staff',
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 登录页已完成网络请求后调用，不再在此处发起 API。
  void markLoggedIn() {
    state = const AuthState(status: AuthStatus.authenticated, role: 'staff');
  }

  Future<void> logout() async {
    final storage = await _ref.read(tokenStorageProvider.future);
    await storage.clearToken();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
