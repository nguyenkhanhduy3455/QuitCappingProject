import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        String message = 'An unexpected network error occurred.';
        if (error.response != null && error.response?.data != null) {
          final data = error.response!.data;
          if (data is Map && data['message'] != null) {
            if (data['message'] is List) {
              message = (data['message'] as List).join(', ');
            } else {
              message = data['message'].toString();
            }
          }
        } else if (error.type == DioExceptionType.connectionTimeout) {
          message = 'Connection timed out. Please check your backend server.';
        } else if (error.type == DioExceptionType.connectionError) {
          message = 'Cannot connect to backend server. Make sure it is running on ${ApiEndpoints.baseUrl}';
        }

        return handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(
              message,
              statusCode: error.response?.statusCode,
              data: error.response?.data,
            ),
          ),
        );
      },
    ),
  );

  return dio;
});
