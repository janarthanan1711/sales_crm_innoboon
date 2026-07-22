import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

/// App router configuration using go_router
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.dashboard,
    refreshListenable: sl<AuthNotifier>(),
    redirect: (context, state) {
      final isAuthenticated = sl<AuthNotifier>().isAuthenticated;
      final loggingIn = state.matchedLocation == RoutePaths.login;
      final forgotPwd = state.matchedLocation == RoutePaths.forgotPassword;

      if (!isAuthenticated && !loggingIn && !forgotPwd) {
        return RoutePaths.login;
      }
      if (isAuthenticated && loggingIn) {
        return RoutePaths.dashboard;
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
