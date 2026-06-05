import 'package:flutter/foundation.dart';

/// 运行环境：正式服务器 / 本地联调 / 手动填写的其它地址
enum ApiEnvironment {
  production,
  local,
  custom,
}

/// API 地址配置：打包前在 [productionBaseUrl] 填写门店服务器地址即可，登录页无需填写。
class ApiEnvConfig {
  ApiEnvConfig._();

  /// 线上门店 API 根地址（不要末尾 `/`）。店员 App 登录时自动使用，无需在界面配置。
  ///
  /// 部署前改成你的域名或 IP，例如 `https://api.example.com` 或 `http://203.0.113.10:8888`。
  /// 也可用编译参数覆盖：`flutter build apk --dart-define=PROD_API_URL=https://api.example.com`
  static const String productionBaseUrl = String.fromEnvironment(
    'PROD_API_URL',
    defaultValue: 'http://43.138.118.104:8888',
  );

  /// 真机调试本机后端时，填电脑局域网 IP（留空则用模拟器默认，见 [localBaseUrl]）。
  /// 例：`http://192.168.1.100:8888`
  static const String localDevOverride = String.fromEnvironment(
    'LOCAL_API_URL',
    defaultValue: '',
  );

  /// 本地联调默认地址（模拟器 / 桌面）
  static String get localBaseUrl {
    if (localDevOverride.trim().isNotEmpty) {
      return normalize(localDevOverride);
    }
    if (kIsWeb) return 'http://127.0.0.1:8888';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8888';
      case TargetPlatform.iOS:
        return 'http://127.0.0.1:8888';
      default:
        return 'http://127.0.0.1:8888';
    }
  }

  static String urlFor(ApiEnvironment env) {
    switch (env) {
      case ApiEnvironment.production:
        return productionBaseUrl;
      case ApiEnvironment.local:
        return localBaseUrl;
      case ApiEnvironment.custom:
        return productionBaseUrl;
    }
  }

  static String normalize(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  static ApiEnvironment detect(String url) {
    final u = normalize(url);
    if (u == normalize(productionBaseUrl)) return ApiEnvironment.production;
    if (u == normalize(localBaseUrl)) return ApiEnvironment.local;
    return ApiEnvironment.custom;
  }

  static String envLabel(ApiEnvironment env) {
    switch (env) {
      case ApiEnvironment.production:
        return '正式环境';
      case ApiEnvironment.local:
        return '本地测试';
      case ApiEnvironment.custom:
        return '自定义';
    }
  }

  static String localHelperText() {
    if (localDevOverride.trim().isNotEmpty) {
      return '本地：$localDevOverride（编译参数 LOCAL_API_URL）';
    }
    return '本地：模拟器 Android 10.0.2.2 / iOS 127.0.0.1；真机请在代码中设置 localDevOverride 或 --dart-define=LOCAL_API_URL=电脑局域网IP';
  }
}
