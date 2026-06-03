import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../models/models.dart';

/// 登录独立请求，不依赖 [ApiClient]，避免与 authProvider 循环依赖。
class AuthRepository {
  Future<LoginResult> login({
    required String apiBaseUrl,
    required String username,
    required String password,
  }) async {
    final base = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final dio = Dio(
      BaseOptions(
        baseUrl: '$base/central/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    try {
      final res = await dio.post<dynamic>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final body = res.data;
      if (body is Map<String, dynamic>) {
        if (body.containsKey('code') &&
            body['code'] != 0 &&
            body['code'] != 200) {
          throw ApiException('${body['msg'] ?? '登录失败'}');
        }
        return LoginResult.fromJson(body);
      }
      throw ApiException('响应格式异常');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${(e.response!.data as Map)['msg'] ?? e.message}'
          : e.message ?? '网络错误，请确认后端已启动且地址正确';
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }
}
