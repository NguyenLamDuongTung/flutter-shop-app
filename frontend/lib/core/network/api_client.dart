import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  final Dio _dio;

  String? token;

  Options get _requestOptions {
    if (token == null) {
      return Options();
    }

    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: _requestOptions,
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: _requestOptions,
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        options: _requestOptions,
      );

      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<void>(path, options: _requestOptions);
    } on DioException catch (error) {
      throw _convertError(error);
    }
  }

  ApiException _convertError(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'];

      if (message != null) {
        return ApiException(
          message.toString(),
          statusCode: error.response?.statusCode,
        );
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        'Cannot reach the server. Check your connection.',
      );
    }

    return ApiException(
      'Something went wrong. Please try again.',
      statusCode: error.response?.statusCode,
    );
  }
}
