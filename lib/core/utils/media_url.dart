import 'package:flutter/foundation.dart';
import '../../app/di/injector.dart';
import '../network/dio_client.dart';

/// Cache-busting token for media whose URL stays the same when its contents
/// change — see [resolveMediaUrl]'s `bustCache`.
///
/// The API derives a user's avatar path from their id (`/media/avatars/12.png`),
/// so replacing the photo leaves the URL byte-for-byte identical and every
/// layer that caches by URL — Flutter's `ImageCache`, `flutter_cache_manager`,
/// the browser's HTTP cache — keeps serving the old image. Bumping this gives
/// the replacement a distinct URL.
///
/// Seeded from the clock so a fresh app run never reuses the previous run's
/// tokens (a restart would otherwise hit the same stale cache entries), and
/// exposed as a listenable so widgets can repaint on a change even when
/// nothing else about their state moved.
final ValueNotifier<int> mediaVersion = ValueNotifier<int>(
  DateTime.now().millisecondsSinceEpoch,
);

/// Call after replacing or deleting a media file that keeps its URL, so
/// cached copies of the old contents stop being served.
void bumpMediaVersion() => mediaVersion.value++;

/// Resolves a possibly-relative media path (e.g. `/media/avatars/12.png`,
/// as returned by `avatar_url`) against the API's origin. The API base URL
/// includes the `/api/v1` prefix, which media paths are not nested under.
///
/// Pass [bustCache] for media served from a path that outlives its contents
/// (avatars) to append the current [mediaVersion]. Leave it off for immutable
/// files like document downloads, which should stay cacheable.
String? resolveMediaUrl(String? path, {bool bustCache = false}) {
  if (path == null || path.isEmpty) return null;
  final String url;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    url = path;
  } else {
    final baseUrl = sl<DioClient>().dio.options.baseUrl;
    final origin = baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    url = '$origin${path.startsWith('/') ? path : '/$path'}';
  }
  if (!bustCache) return url;
  return '$url${url.contains('?') ? '&' : '?'}v=${mediaVersion.value}';
}
