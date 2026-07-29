import 'package:flutter/foundation.dart';
import '../../features/auth/domain/entities/user.dart';

/// Notifier to publish authentication state changes to GoRouter.
class AuthNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  // True until the app's initial AuthCheckRequested resolves. While true,
  // the router defers its authenticated/unauthenticated redirect so a page
  // refresh on a deep link (e.g. /leads/123) isn't bounced through /login
  // and dumped on the dashboard before the cached-session check completes.
  bool _isChecking = true;

  // The signed-in user, kept here so the router's `redirect` can gate routes
  // on permissions. It can't read AuthBloc instead: the bloc is registered as
  // a factory, so `sl<AuthBloc>()` would hand back a fresh, stateless one.
  User? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isChecking => _isChecking;
  User? get user => _user;

  /// True if the current user holds any of [codes]. An empty [codes] means
  /// "no permission required", so it passes for any signed-in user.
  bool hasAnyPermission(List<String> codes) =>
      codes.isEmpty || (_user?.hasAnyPermission(codes) ?? false);

  void setAuthenticated(bool value, {User? user}) {
    final changed =
        _isAuthenticated != value ||
        _isChecking ||
        _user != (value ? user : null);
    _isAuthenticated = value;
    // Drop the user on sign-out so no stale permissions linger.
    _user = value ? user : null;
    _isChecking = false;
    if (changed) notifyListeners();
  }
}
