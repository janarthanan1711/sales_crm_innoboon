import '../../app/di/injector.dart';
import '../network/dio_client.dart';

/// Resolves a possibly-relative media path (e.g. `/media/avatars/12.png`,
/// as returned by `avatar_url`) against the API's origin. The API base URL
/// includes the `/api/v1` prefix, which media paths are not nested under.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final baseUrl = sl<DioClient>().dio.options.baseUrl;
  final origin = baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
  return '$origin${path.startsWith('/') ? path : '/$path'}';
}
