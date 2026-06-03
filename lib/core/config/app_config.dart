import 'api_env_config.dart';

/// 应用配置：API 地址等。
class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
  });

  /// 未保存过地址时的默认值（正式服务器，见 [ApiEnvConfig.productionBaseUrl]）。
  static String get defaultApiBaseUrl => ApiEnvConfig.productionBaseUrl;

  final String apiBaseUrl;

  String get apiPrefix => '$apiBaseUrl/central/v1';

  String get healthUrl => '$apiBaseUrl/health';
}
