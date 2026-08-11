import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/app.dart';
import 'app/di/injector.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Default hash-based URLs (`/#/leads/3`) can't carry a real path/query from
  // an external link — e.g. the emailed password-reset link is a plain
  // `/reset-password?token=...` with no `#`, which the hash strategy ignores
  // entirely on boot, sending it to whatever the default route resolves to
  // instead. Path-based URLs make the browser's actual path/query the source
  // of truth for the initial route, same as this app's non-web behavior. On
  // real hosting this needs the server to fall back to index.html for
  // unknown paths (nginx `try_files`, a `_redirects`/rewrite rule, etc.).
  usePathUrlStrategy();
  await initDependencies();
  // Resolve the stored theme before the first frame — registering it after
  // runApp would paint one frame of light mode for a dark-mode user.
  sl<ThemeController>().hydrate(await ThemeController.load());
  runApp(const SalesHubApp());
}
