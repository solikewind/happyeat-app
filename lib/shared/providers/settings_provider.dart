import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_env_config.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

export '../../core/config/api_env_config.dart' show ApiEnvironment;

class SettingsState {
  const SettingsState({
    required this.apiBaseUrl,
    required this.env,
  });

  final String apiBaseUrl;
  final ApiEnvironment env;

  SettingsState copyWith({
    String? apiBaseUrl,
    ApiEnvironment? env,
  }) {
    return SettingsState(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      env: env ?? this.env,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref)
      : super(
          SettingsState(
            apiBaseUrl: AppConfig.defaultApiBaseUrl,
            env: ApiEnvironment.production,
          ),
        ) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final storage = await _ref.read(tokenStorageProvider.future);
    final saved = storage.getApiBaseUrl();
    if (saved != null && saved.isNotEmpty) {
      final url = ApiEnvConfig.normalize(saved);
      final env = _envFromStorage(storage.getApiEnv(), url);
      state = SettingsState(apiBaseUrl: url, env: env);
      return;
    }
    state = SettingsState(
      apiBaseUrl: ApiEnvConfig.productionBaseUrl,
      env: ApiEnvironment.production,
    );
  }

  ApiEnvironment _envFromStorage(String? stored, String url) {
    if (stored == ApiEnvironment.production.name) {
      return ApiEnvironment.production;
    }
    if (stored == ApiEnvironment.local.name) {
      return ApiEnvironment.local;
    }
    return ApiEnvConfig.detect(url);
  }

  Future<void> _persist(String url, ApiEnvironment env) async {
    final trimmed = ApiEnvConfig.normalize(url);
    state = SettingsState(apiBaseUrl: trimmed, env: env);
    final storage = await _ref.read(tokenStorageProvider.future);
    await storage.setApiBaseUrl(trimmed);
    await storage.setApiEnv(env.name);
  }

  /// 登录成功后仅更新地址，不触发 apiClient 重建（避免循环依赖）。
  void applyBaseUrl(String url) {
    final trimmed = ApiEnvConfig.normalize(url);
    state = SettingsState(
      apiBaseUrl: trimmed,
      env: ApiEnvConfig.detect(trimmed),
    );
  }

  /// 切换正式 / 本地（会写存储并应 invalidate apiClientProvider）。
  Future<void> switchEnvironment(ApiEnvironment env) async {
    if (env == ApiEnvironment.custom) return;
    await _persist(ApiEnvConfig.urlFor(env), env);
  }

  /// 设置页 / 登录页保存自定义地址。
  Future<void> persistBaseUrl(String url) async {
    final trimmed = ApiEnvConfig.normalize(url);
    await _persist(trimmed, ApiEnvConfig.detect(trimmed));
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
