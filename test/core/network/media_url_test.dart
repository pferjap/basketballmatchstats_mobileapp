import 'package:flutter_test/flutter_test.dart';
import 'package:hoop_analytics/core/network/media_url.dart';

void main() {
  group('resolveMediaUrl', () {
    test('returns null for null or empty input', () {
      expect(resolveMediaUrl(null, baseUrl: 'http://10.0.2.2:3001/'), isNull);
      expect(resolveMediaUrl('', baseUrl: 'http://10.0.2.2:3001/'), isNull);
      expect(resolveMediaUrl('   ', baseUrl: 'http://10.0.2.2:3001/'), isNull);
    });

    test('returns absolute URLs untouched', () {
      const url = 'https://cdn.example.com/logo.webp';
      expect(resolveMediaUrl(url, baseUrl: 'http://10.0.2.2:3001/'), url);
    });

    test('prefixes a root-relative path with the API origin', () {
      expect(
        resolveMediaUrl(
          '/uploads/clubs/abc.webp',
          baseUrl: 'http://10.0.2.2:3001/',
        ),
        'http://10.0.2.2:3001/uploads/clubs/abc.webp',
      );
    });

    test('adds a leading slash to a bare relative path', () {
      expect(
        resolveMediaUrl(
          'uploads/clubs/abc.webp',
          baseUrl: 'http://10.0.2.2:3001/',
        ),
        'http://10.0.2.2:3001/uploads/clubs/abc.webp',
      );
    });

    test('uses only the origin, dropping any REST path prefix', () {
      expect(
        resolveMediaUrl(
          '/uploads/a.webp',
          baseUrl: 'https://staging-api.hoopanalytics.com/api/v1',
        ),
        'https://staging-api.hoopanalytics.com/uploads/a.webp',
      );
    });
  });
}
