import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import '../../data/local/token_storage.dart';

typedef UnauthorizedHandler = void Function();

class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStorage storage,
    this.onUnauthorized,
  })  : _config = config,
        _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiPrefix,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final AppConfig _config;
  final TokenStorage _storage;
  final UnauthorizedHandler? onUnauthorized;
  late final Dio _dio;

  AppConfig get config => _config;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _safe(_dio.get<dynamic>(path, queryParameters: query));

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) =>
      _safe(_dio.post<dynamic>(path, data: data));

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) =>
      _safe(_dio.put<dynamic>(path, data: data));

  Future<Map<String, dynamic>> delete(String path) =>
      _safe(_dio.delete<dynamic>(path));

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fieldName,
    required String filePath,
    String? fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });
      return _unwrap(
        await _dio.post<dynamic>(
          path,
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        ),
      );
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  Future<bool> checkHealth() async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
      final res = await dio.get<dynamic>(_config.healthUrl);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _unwrap(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      // go-zero 业务错误：{ code, msg }
      if (body.containsKey('code') && body['code'] != 0 && body['code'] != 200) {
        throw ApiException('${body['msg'] ?? '请求失败'}');
      }
      return body;
    }
    if (body == null) return {};
    throw ApiException('响应格式异常');
  }

  Never _rethrow(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['msg'];
      if (msg != null && '$msg'.trim().isNotEmpty) {
        throw ApiException('$msg', statusCode: status);
      }
    }
    if (status == 500) {
      throw ApiException(
        '服务器异常（500）${data is Map && data['msg'] != null ? '：${data['msg']}' : '，请查看后端日志或确认服务已启动'}',
        statusCode: status,
      );
    }
    if (status == 401) {
      throw ApiException('登录已失效，请重新登录', statusCode: status);
    }
    if (status == 403) {
      throw ApiException('无权限访问该接口', statusCode: status);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw ApiException('连接超时，请检查服务器地址与网络', statusCode: status);
    }
    if (e.type == DioExceptionType.connectionError) {
      throw ApiException('无法连接服务器，请检查地址与端口（默认 8888）', statusCode: status);
    }
    throw ApiException('网络请求失败${status != null ? '（$status）' : ''}', statusCode: status);
  }

  Future<Map<String, dynamic>> _safe(Future<Response<dynamic>> future) async {
    try {
      return _unwrap(await future);
    } on DioException catch (e) {
      _rethrow(e);
    }
  }
}

final tokenStorageProvider = FutureProvider<TokenStorage>((ref) async {
  return TokenStorage.create();
});

final appConfigProvider = Provider<AppConfig>((ref) {
  // 运行时由 settings 覆盖；默认开发地址
  return AppConfig(apiBaseUrl: AppConfig.defaultApiBaseUrl);
});
