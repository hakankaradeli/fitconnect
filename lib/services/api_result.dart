sealed class ApiResult<T> {
  const ApiResult();

  factory ApiResult.success(T data, {int statusCode}) = ApiSuccess<T>;
  factory ApiResult.failure(String message, {int? statusCode, dynamic error}) = ApiFailure<T>;

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(data: final d) => d,
    ApiFailure<T>() => null,
  };

  String? get errorOrNull => switch (this) {
    ApiSuccess<T>() => null,
    ApiFailure<T>(message: final m) => m,
  };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message, int? statusCode) onFailure,
  }) {
    return switch (this) {
      ApiSuccess<T>(data: final d) => onSuccess(d),
      ApiFailure<T>(message: final m, statusCode: final code) => onFailure(m, code),
    };
  }

  static Future<ApiResult<T>> guard<T>(Future<T> Function() computation) async {
    try {
      final result = await computation();
      return ApiResult.success(result);
    } catch (e) {
      return ApiResult.failure(e.toString(), error: e);
    }
  }
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  final int statusCode;

  const ApiSuccess(this.data, {this.statusCode = 200});

  @override
  String toString() => 'ApiSuccess(statusCode: $statusCode, data: $data)';
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  final dynamic error;

  const ApiFailure(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'ApiFailure(statusCode: $statusCode, message: $message, error: $error)';
}
