import '../error/error_mapper.dart';

/// Pagination metadata from the API response wrapper (`meta`).
class ApiMeta {
  const ApiMeta({this.page, this.limit, this.total});

  factory ApiMeta.fromJson(Map<String, dynamic> json) => ApiMeta(
        page: (json['page'] as num?)?.toInt(),
        limit: (json['limit'] as num?)?.toInt(),
        total: (json['total'] as num?)?.toInt(),
      );

  final int? page;
  final int? limit;
  final int? total;
}

/// Parses the standard backend response wrapper:
/// `{ success, statusCode, data, meta, timestamp }` (Agent_Mobile.md §6).
///
/// On a non-success body it throws a `ServerException` built from the `errors`
/// list, so callers only deal with the unwrapped `data`.
abstract final class ApiResponseParser {
  /// Extracts and maps the `data` field of a successful response.
  ///
  /// Throws `ServerException` if `success` is not `true`.
  static T data<T>(
    Map<String, dynamic> body,
    T Function(Object? data) fromData,
  ) {
    if (body['success'] != true) {
      throw ErrorMapper.exceptionFromResponse(body);
    }
    return fromData(body['data']);
  }

  /// Returns the pagination [ApiMeta], if present.
  static ApiMeta? meta(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map<String, dynamic>) {
      return ApiMeta.fromJson(meta);
    }
    return null;
  }
}
