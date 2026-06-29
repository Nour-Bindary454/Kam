import 'package:dio/dio.dart';
import 'package:kam/core/services/token_manager.dart';

class DioHelper {
  static late Dio dio;

  static Future<void> init() async {
    final token = await TokenManager.getToken();

    dio = Dio(
      BaseOptions(
        baseUrl: "https://your-base-url.com",
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<void> updateToken() async {
    final token = await TokenManager.getToken();

    dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
