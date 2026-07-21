/// Route path constants
class RoutePaths {
  RoutePaths._();

  // ─── Auth ──────────────────────────────────────────────
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // ─── Main Shell ────────────────────────────────────────
  static const String dashboard = '/';
  static const String leads = '/leads';
  static const String leadDetail = '/leads/:id';
  static const String editLead = '/leads/:id/edit';
  static const String createLead = '/leads/create';
  static const String accounts = '/accounts';
  static const String accountDetail = '/accounts/:id';
  static const String createAccount = '/accounts/create';
  static const String deals = '/deals';
  static const String dealDetail = '/deals/:id';
  static const String createDeal = '/deals/create';
  static const String staffAugmentation = '/staff-augmentation';
  static const String documents = '/documents';
  static const String activity = '/activity';
  static const String tasks = '/tasks';
  static const String notifications = '/notifications';
  static const String analytics = '/analytics';
  static const String leaderboard = '/leaderboard';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String support = '/support';
}
