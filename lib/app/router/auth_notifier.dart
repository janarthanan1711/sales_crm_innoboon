import 'package:flutter/foundation.dart';

/// Notifier to publish authentication state changes to GoRouter.
class AuthNotifier extends ChangeNotifier {
  bool _isAuthenticated = false;

  // True until the app's initial AuthCheckRequested resolves. While true,
  // the router defers its authenticated/unauthenticated redirect so a page
  // refresh on a deep link (e.g. /leads/123) isn't bounced through /login
  // and dumped on the dashboard before the cached-session check completes.
  bool _isChecking = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isChecking => _isChecking;

  void setAuthenticated(bool value) {
    final changed = _isAuthenticated != value || _isChecking;
    _isAuthenticated = value;
    _isChecking = false;
    if (changed) notifyListeners();
  }
}
