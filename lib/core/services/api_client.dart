import 'package:dio/dio.dart';
import 'user_service.dart';

class ApiClient {
  
  static const String baseUrl = 'https://venuemate-backend-production-3082.up.railway.app/api';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  static void init() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await UserService.getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          UserService.clearUser();
        }
        handler.next(error);
      },
    ));
  }

  static Future<Map<String, dynamic>> get(
    String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get(path, queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> post(
    String path, Map<String, dynamic> body) async {
    final res = await _dio.post(path, data: body);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(
    String path, Map<String, dynamic> body) async {
    final res = await _dio.put(path, data: body);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await _dio.delete(path);
    return res.data as Map<String, dynamic>;
  }
}