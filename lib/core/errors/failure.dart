import 'package:dio/dio.dart';

abstract class Failure {
  final String errMessage;
  Failure(this.errMessage);
}

class ServerFailure extends Failure {
  ServerFailure(super.errMessage);

  factory ServerFailure.fromDioError(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return ServerFailure("connectionTimeOut");

      case DioExceptionType.sendTimeout:
        return ServerFailure("sendTimeOut");

      case DioExceptionType.receiveTimeout:
        return ServerFailure("receiveTimeOut");

      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          dioException.response?.statusCode ?? 0,
          dioException.response?.data,
        );

      case DioExceptionType.cancel:
        return ServerFailure("requestCanceled");

      case DioExceptionType.unknown:
        if (dioException.error.toString().contains("SocketException")) {
          return ServerFailure("noInternet");
        }
        return ServerFailure("unexpectedError");

      default:
        return ServerFailure("Something went wrong. Try again");
    }
  }

  factory ServerFailure.fromResponse(int statusCode, dynamic response) {
    String errorMessage = "Something went wrong. Please try again";

    if (response is Map<String, dynamic>) {
      // ✅ Validation Errors (422)
      if (statusCode == 422 && response["data"] is Map<String, dynamic>) {
        final Map<String, dynamic> errors =
            response["data"] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final String firstKey = errors.keys.first;
          final dynamic firstError = errors[firstKey];

          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }

        return ServerFailure(errorMessage);
      }

      // ✅ Validation Errors (422)
      if (statusCode == 404 && response["data"] is Map<String, dynamic>) {
        final Map<String, dynamic> errors =
            response["data"] as Map<String, dynamic>;

        if (errors.isNotEmpty) {
          final String firstKey = errors.keys.first;
          final dynamic firstError = errors[firstKey];

          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          }
        }

        return ServerFailure(errorMessage);
      }

      // الرسالة العامة
      errorMessage = response["message"]?.toString() ?? errorMessage;
    } else if (response is String && response.isNotEmpty) {
      errorMessage = response;
    }

    // حالات status code مختلفة
    if (statusCode == 400 ||
        statusCode == 401 ||
        statusCode == 403 ||
        statusCode == 404 ||
        statusCode == 500) {
      return ServerFailure(errorMessage);
    }

    return ServerFailure(errorMessage);
  }
}
