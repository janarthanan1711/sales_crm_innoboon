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
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

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
  static String accountActivities(String id) => '/accounts/$id/activities';
  static String accountActivityById(String accountId, String activityId) =>
      '/accounts/$accountId/activities/$activityId';
  static String accountDocuments(String id) => '/accounts/$id/documents';
  static String accountDocumentById(String accountId, String documentId) =>
      '/accounts/$accountId/documents/$documentId';

  // ─── Contacts ──────────────────────────────────────────
  static const String contacts = '/contacts';
  // Bulk import: download a sample template, then POST a filled .csv/.xlsx.
  static const String contactsImport = '/contacts/import';
  static const String contactsImportTemplate = '/contacts/import/template';
  static String contactById(String id) => '/contacts/$id';
  static String contactOverview(String id) => '/contacts/$id/overview';
  static String contactDeals(String id) => '/contacts/$id/deals';

  // ─── Deals ─────────────────────────────────────────────
  // Stage changes go through the same PATCH /deals/{id} used for any other
  // deal update — the backend has no separate /stage sub-route.
  // Export is not a separate route — pass `to_export=true` on GET /deals
  // (see SalesHub API doc §6.3). Same pattern for leads/accounts/contacts.
  static const String deals = '/deals';
  static String dealById(String id) => '/deals/$id';
  static String dealStageHistory(String id) => '/deals/$id/stage-history';
  static String dealActivities(String id) => '/deals/$id/activities';
  static String dealActivityById(String dealId, String activityId) =>
      '/deals/$dealId/activities/$activityId';
  static String dealDocuments(String id) => '/deals/$id/documents';
  static String dealDocumentById(String dealId, String documentId) =>
      '/deals/$dealId/documents/$documentId';

  // ─── Deal Stages (dynamic, admin-configurable pipeline) ─
  static const String dealStages = '/deal-stages';
  static String dealStageById(String id) => '/deal-stages/$id';

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

  /// Read state is toggled by `PATCH`ing `is_read` on the notification itself
  /// (doc §9.3) — the older `/{id}/read` and `/{id}/unread` action routes are
  /// gone.
  static String notificationById(String id) => '/notifications/$id';

  // ─── Search ────────────────────────────────────────────
  static const String search = '/search';

  // ─── Dashboard ─────────────────────────────────────────
  // Single combined endpoint powering the whole dashboard page in one call.
  static const String dashboard = '/dashboard';
  static const String dashboardPerformance = '/dashboard/performance';
  static const String dashboardStats = '/dashboard/stats';

  // ─── Staff Augmentation ────────────────────────────────
  static const String resources = '/resources';
  static const String staffAugOpportunities = '/staff-aug-opportunities';
  static String staffAugFeedback(String id) =>
      '/staff-aug-opportunities/$id/feedback';

  // ─── Audit Log ─────────────────────────────────────────
  static const String auditLog = '/audit-log';

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
