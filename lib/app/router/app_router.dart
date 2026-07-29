import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/permissions.dart';
import '../di/injector.dart';
import 'auth_notifier.dart';
import 'route_paths.dart';
import '../shell/app_shell.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/leads/presentation/pages/leads_list_page.dart';
import '../../features/leads/presentation/pages/lead_detail_page.dart';
import '../../features/leads/presentation/pages/create_lead_page.dart';
import '../../features/leads/domain/entities/lead.dart';
import '../../features/accounts/presentation/pages/accounts_list_page.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/create_account_page.dart';
import '../../features/deals/presentation/pages/deals_list_page.dart';
import '../../features/deals/presentation/pages/deal_detail_page.dart';
import '../../features/contacts/presentation/pages/contacts_list_page.dart';
import '../../features/contacts/presentation/pages/contact_detail_page.dart';

import '../../features/staff_augmentation/presentation/pages/staff_augmentation_page.dart';
import '../../features/documents/presentation/pages/documents_page.dart';
import '../../features/activity_log/presentation/pages/activity_log_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/performance_dashboard/presentation/pages/analytics_page.dart';
import '../../features/admin/presentation/pages/admin_settings_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Global navigator key
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

/// Permission codes required to open a route, keyed by its path *pattern*
/// (matched against [GoRouterState.fullPath], so `:id` routes are covered).
/// Holding ANY listed code grants access; routes absent from this map are
/// open to every signed-in user.
///
/// These mirror the nav-item gates in [AppShell] and the page-level gates on
/// the create/edit screens, so a hidden button can't be reached by typing its
/// URL either. Create/edit paths need `<module>.access` ("view and manage
/// own"); list/detail paths also accept `.view_all` (read-only visibility).
const Map<String, List<String>> _routePermissions = {
  RoutePaths.leads: [Perms.leadsManage, Perms.leadsViewAll],
  RoutePaths.leadDetail: [Perms.leadsManage, Perms.leadsViewAll],
  RoutePaths.createLead: [Perms.leadsManage],
  RoutePaths.editLead: [Perms.leadsManage],
  RoutePaths.accounts: [Perms.accountsManage, Perms.accountsViewAll],
  RoutePaths.accountDetail: [Perms.accountsManage, Perms.accountsViewAll],
  RoutePaths.createAccount: [Perms.accountsManage],
  RoutePaths.deals: [Perms.dealsManage, Perms.dealsViewAll],
  RoutePaths.dealDetail: [Perms.dealsManage, Perms.dealsViewAll],
  RoutePaths.contacts: [Perms.contactsManage],
  RoutePaths.contactDetail: [Perms.contactsManage],
  RoutePaths.settings: [Perms.usersManage, Perms.rolesManage],
};

/// App router configuration using go_router
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.dashboard,
    refreshListenable: sl<AuthNotifier>(),
    redirect: (context, state) {
      final authNotifier = sl<AuthNotifier>();
      // Defer redirect decisions until the initial cached-session check
      // resolves — otherwise a page refresh briefly reads as "unauthenticated"
      // and gets redirected to /login before the real state is known, and the
      // originally requested deep link (e.g. /leads/123) is lost.
      if (authNotifier.isChecking) return null;

      final isAuthenticated = authNotifier.isAuthenticated;
      final loggingIn = state.matchedLocation == RoutePaths.login;
      final forgotPwd = state.matchedLocation == RoutePaths.forgotPassword;

      if (!isAuthenticated && !loggingIn && !forgotPwd) {
        return RoutePaths.login;
      }
      if (isAuthenticated && loggingIn) {
        return RoutePaths.dashboard;
      }

      // Permission gate. Keeps a route the user can't act on out of reach even
      // when its button is hidden — typed URLs, bookmarks and stale links all
      // land here. The dashboard requires no permission, so it's always a safe
      // place to bounce to.
      if (isAuthenticated) {
        final required = _routePermissions[state.fullPath ?? ''];
        if (required != null && !authNotifier.hasAnyPermission(required)) {
          return RoutePaths.dashboard;
        }
      }
      return null;
    },
    routes: [
      // ─── Auth Routes (outside shell) ─────────────────
      GoRoute(
        path: RoutePaths.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ─── Main Shell Routes ───────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: RoutePaths.leads,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LeadsListPage()),
          ),
          GoRoute(
            path: RoutePaths.createLead,
            builder: (context, state) => const CreateLeadPage(),
          ),
          GoRoute(
            path: RoutePaths.editLead,
            builder: (context, state) {
              final lead = state.extra as Lead?;
              return CreateLeadPage(lead: lead);
            },
          ),
          GoRoute(
            path: RoutePaths.leadDetail,
            builder: (context, state) =>
                LeadDetailPage(leadId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RoutePaths.accounts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AccountsListPage()),
          ),
          GoRoute(
            path: RoutePaths.createAccount,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CreateAccountPage()),
          ),
          GoRoute(
            path: RoutePaths.accountDetail,
            builder: (context, state) =>
                AccountDetailPage(accountId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RoutePaths.deals,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DealsListPage()),
          ),

          GoRoute(
            path: RoutePaths.dealDetail,
            builder: (context, state) =>
                DealDetailPage(dealId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RoutePaths.contacts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ContactsListPage()),
          ),
          GoRoute(
            path: RoutePaths.contactDetail,
            builder: (context, state) =>
                ContactDetailPage(contactId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: RoutePaths.staffAugmentation,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StaffAugmentationPage()),
          ),
          GoRoute(
            path: RoutePaths.documents,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DocumentsPage()),
          ),
          GoRoute(
            path: RoutePaths.activity,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ActivityLogPage()),
          ),
          GoRoute(
            path: RoutePaths.tasks,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TasksPage()),
          ),
          GoRoute(
            path: RoutePaths.notifications,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsPage()),
          ),
          GoRoute(
            path: RoutePaths.analytics,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnalyticsPage()),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminSettingsPage()),
          ),
          GoRoute(
            path: RoutePaths.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
    ],
  );
}
