import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kam/core/errors/failure.dart';
import 'package:kam/core/services/cache_helper.dart';
import 'package:kam/core/services/end_points.dart';
import 'package:kam/core/services/token_manager.dart';

class ApiService {
  final Dio _dio;

  ApiService(this._dio) {
    _dio.options = BaseOptions(
      baseUrl: EndPoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json, // 🔥 مهم جدًا
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          debugPrint("➡️ [REQUEST] ${options.method} ${options.uri}");
          return handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint(
            "✅ [RESPONSE] [${response.statusCode}] ${response.requestOptions.uri}",
          );

          final data = response.data;
          if (data is String && data.contains("<html")) {
            throw DioException(
              requestOptions: response.requestOptions,
              error: "Server returned HTML instead of JSON",
              type: DioExceptionType.badResponse,
            );
          }

          return handler.next(response);
        },

        onError: (DioException error, handler) async {
          debugPrint("❌ [ERROR] ${error.message}");

          if (error.response?.statusCode == 401) {
            final requestPath = error.requestOptions.path;
            if (!requestPath.startsWith("auth/")) {
              debugPrint(
                "🚨 [401 Unauthorized] Session expired. Clearing session & redirecting to login.",
              );
              await TokenManager.clear();
              await CacheHelper.removeData(key: 'token');
              await CacheHelper.removeData(key: 'role');
              // navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }

          final failure = ServerFailure.fromDioError(error);
          return handler.reject(error.copyWith(error: failure));
        },
      ),
    );
  }

  Future<Response> postData({
    required String endPoint,
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    return _dio.post(endPoint, data: data, queryParameters: query);
  }

  Future<Response> getData({
    required String endPoint,
    Map<String, dynamic>? query,
  }) async {
    return _dio.get(endPoint, queryParameters: query);
  }

  Future<Response> putData({
    required String endPoint,
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    return _dio.put(endPoint, data: data, queryParameters: query);
  }

  Future<Response> patchData({
    required String endPoint,
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    return _dio.patch(endPoint, data: data, queryParameters: query);
  }

  Future<Response> deleteData({
    required String endPoint,
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    return _dio.delete(endPoint, data: data, queryParameters: query);
  }
}
