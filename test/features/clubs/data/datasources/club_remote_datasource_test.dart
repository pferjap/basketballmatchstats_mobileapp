import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/features/clubs/data/datasources/club_remote_datasource.dart';

/// Captures the outgoing request and returns a canned success body.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{"success":true,"data":{"id":"club-1","name":"Valencia",'
      '"logoUrl":"/uploads/clubs/club-1.webp"}}',
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ClubRemoteDataSource.uploadLogo', () {
    test('posts multipart to /clubs/:id/logo and parses the response', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = adapter;
      final dataSource = ClubRemoteDataSource(dio);

      final model = await dataSource.uploadLogo(
        'club-1',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        filename: 'logo.png',
      );

      expect(adapter.captured?.method, 'POST');
      expect(adapter.captured?.path, '/clubs/club-1/logo');
      expect(adapter.captured?.data, isA<FormData>());
      final form = adapter.captured!.data as FormData;
      expect(form.files.map((MapEntry<String, MultipartFile> e) => e.key),
          contains('file'));
      expect(form.files.single.value.filename, 'logo.png');

      expect(model.id, 'club-1');
      expect(model.logoUrl, '/uploads/clubs/club-1.webp');
    });
  });
}
