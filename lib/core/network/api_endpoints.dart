/// API endpoint constants — paths as actually implemented by `saleshub`
/// (see `app/api/v1/*.py`). Base URL includes the `/api/v1` prefix, so
/// paths here start from the resource root (e.g. `/auth/login`).
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Auth ──────────────────────────────────────────────
  // No register or /me endpoint.
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ─── Users ─────────────────────────────────────────────
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String usersMe = '/users/me';
  static const String usersMePassword = '/users/me/password';
  static const String usersMeAvatar = '/users/me/avatar';

  // ─── Leads ─────────────────────────────────────────────
  static const String leads = '/leads';
  static String leadById(String id) => '/leads/$id';
  static String convertLead(String id) => '/leads/$id/convert';
  static String leadActivities(String id) => '/leads/$id/activities';
  // Bulk import: download a sample template, then POST a filled .csv/.xlsx.
  static const String leadsImport = '/leads/import';
  static const String leadsImportTemplate = '/leads/import/template';

  // ─── Accounts ──────────────────────────────────────────
  static const String accounts = '/accounts';
  static String accountById(String id) => '/accounts/$id';
  static String accountOverview(String id) => '/accounts/$id/overview';
  // GET lists contacts; POST creates-or-updates + links (contact_accounts).
  static String accountContacts(String id) => '/accounts/$id/contacts';
  static String accountDeals(String id) => '/accounts/$id/deals';

  // ─── Contacts ──────────────────────────────────────────
  static const String contacts = '/contacts';
  static String contactById(String id) => '/contacts/$id';

  // ─── Deals ─────────────────────────────────────────────
  // Stage changes go through the same PATCH /deals/{id} used for any other
  // deal update — the backend has no separate /stage sub-route.
  static const String deals = '/deals';
  static String dealById(String id) => '/deals/$id';
  static String dealStageHistory(String id) => '/deals/$id/stage-history';

  // ─── Checklist ─────────────────────────────────────────
  static String checklistByAccount(String accountId) => '/checklist/$accountId';
  static String checklistItem(String id) => '/checklist-items/$id';

  // ─── Tasks ─────────────────────────────────────────────
  static const String tasks = '/tasks';
  static String taskById(String id) => '/tasks/$id';

  // ─── Notifications ─────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  // ─── Search ────────────────────────────────────────────
  static const String search = '/search';

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
  static const String adminChecklistTemplate = '/admin/checklist-template';

  // ─── Permissions ───────────────────────────────────────
  static const String permissions = '/permissions';

  // ─── Roles ─────────────────────────────────────────────
  static const String roles = '/roles';
  static String roleById(String id) => '/roles/$id';
}
