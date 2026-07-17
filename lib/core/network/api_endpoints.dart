/// API endpoint constants.
/// Stubbed paths — update when backend contracts are confirmed.
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ──────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ─── Leads ─────────────────────────────────────────────
  static const String leads = '/leads';
  static String leadById(String id) => '/leads/$id';
  static String convertLeadToAccount(String id) =>
      '/leads/$id/convert-to-account';
  static const String checkDuplicateLead = '/leads/check-duplicate';

  // ─── Accounts ──────────────────────────────────────────
  static const String accounts = '/accounts';
  static String accountById(String id) => '/accounts/$id';

  // ─── Contacts ──────────────────────────────────────────
  static const String contacts = '/contacts';
  static String contactById(String id) => '/contacts/$id';

  // ─── Deals ─────────────────────────────────────────────
  static const String deals = '/deals';
  static String dealById(String id) => '/deals/$id';
  static String updateDealStage(String id) => '/deals/$id/stage';
  static String dealStageHistory(String id) => '/deals/$id/stage-history';

  // ─── Checklist ─────────────────────────────────────────
  static String checklistByAccount(String accountId) =>
      '/checklist/$accountId';
  static String checklistItem(String id) => '/checklist-items/$id';

  // ─── Tasks ─────────────────────────────────────────────
  static const String tasks = '/tasks';
  static String taskById(String id) => '/tasks/$id';

  // ─── Notifications ─────────────────────────────────────
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) =>
      '/notifications/$id/read';

  // ─── Dashboard ─────────────────────────────────────────
  static const String dashboardPerformance = '/dashboard/performance';
  static const String dashboardStats = '/dashboard/stats';

  // ─── Staff Augmentation ────────────────────────────────
  static const String resources = '/resources';
  static const String staffAugOpportunities = '/staff-aug-opportunities';
  static String staffAugFeedback(String id) =>
      '/staff-aug-opportunities/$id/feedback';

  // ─── Documents ─────────────────────────────────────────
  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';
  static String documentVersions(String id) => '/documents/$id/versions';

  // ─── Activity ──────────────────────────────────────────
  static const String activities = '/activity';

  // ─── Admin ─────────────────────────────────────────────
  static const String adminUsers = '/admin/users';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static const String adminChecklistTemplate = '/admin/checklist-template';
}
