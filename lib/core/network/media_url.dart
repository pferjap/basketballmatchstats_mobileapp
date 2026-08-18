import '../config/env_config.dart';

/// Resolves a media path returned by the API into an absolute, loadable URL.
///
/// Uploaded images (club/team logos, player photos) are exposed by the backend
/// as root-relative paths such as `/uploads/abc.webp`, served from the API
/// origin rather than the `/api/v1` REST prefix. This helper combines such a
/// path with the current environment's origin (scheme + authority). Absolute
/// URLs are returned untouched, and `null`/empty inputs yield `null`.
String? resolveMediaUrl(String? path, {String? baseUrl}) {
  if (path == null) {
    return null;
  }
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final base = baseUrl ?? EnvConfig.instance.baseUrl;
  final origin = Uri.parse(base);
  final relative = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '${origin.scheme}://${origin.authority}$relative';
}
