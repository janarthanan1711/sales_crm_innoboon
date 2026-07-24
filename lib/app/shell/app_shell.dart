import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_constants.dart';
import '../router/route_paths.dart';
import '../../features/notifications/presentation/widgets/notification_bell.dart';
import '../../features/search/presentation/widgets/global_search_field.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user.dart';

/// Whether the sidebar "Quick Action" button is shown. Hidden for now
/// (the quick-action menu isn't built yet); flip to true to re-enable.
/// Intentionally non-const so the retained button code isn't flagged as
/// dead code by the analyzer.
final bool _kShowQuickAction = false;

/// Navigation item definition
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  /// Permission codes that grant visibility — the item shows if the user
  /// holds ANY of them. Empty ⇒ visible to any authenticated user.
  final List<String> requiredPermissions;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
    this.requiredPermissions = const [],
  });
}

/// Main navigation items
const List<NavItem> _mainNavItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    path: RoutePaths.dashboard,
  ),
  NavItem(
    label: 'Leads',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    path: RoutePaths.leads,
    requiredPermissions: ['leads.access', 'leads.view_all'],
  ),
  NavItem(
    label: 'Deals',
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake,
    path: RoutePaths.deals,
    requiredPermissions: ['deals.access', 'deals.view_all'],
  ),
  NavItem(
    label: 'Accounts',
    icon: Icons.business_outlined,
    activeIcon: Icons.business,
    path: RoutePaths.accounts,
    requiredPermissions: ['accounts.access', 'accounts.view_all'],
  ),
  NavItem(
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics,
    path: RoutePaths.analytics,
  ),
  NavItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    path: RoutePaths.settings,
    requiredPermissions: ['users.manage', 'roles.manage'],
  ),
];

/// Full sidebar items (web only)
const List<NavItem> _sidebarMainItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    path: RoutePaths.dashboard,
  ),
  NavItem(
    label: 'Leads',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    path: RoutePaths.leads,
    requiredPermissions: ['leads.access', 'leads.view_all'],
  ),
  NavItem(
    label: 'Deals',
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake,
    path: RoutePaths.deals,
    requiredPermissions: ['deals.access', 'deals.view_all'],
  ),
  NavItem(
    label: 'Accounts',
    icon: Icons.business_outlined,
    activeIcon: Icons.business,
    path: RoutePaths.accounts,
    requiredPermissions: ['accounts.access', 'accounts.view_all'],
  ),
  NavItem(
    label: 'Staff Augmentation',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    path: RoutePaths.staffAugmentation,
  ),
  NavItem(
    label: 'Documents',
    icon: Icons.description_outlined,
    activeIcon: Icons.description,
    path: RoutePaths.documents,
  ),
  // NavItem(
  //   label: 'Activity',
  //   icon: Icons.timeline_outlined,
  //   activeIcon: Icons.timeline,
  //   path: RoutePaths.activity,
  // ),
];

const List<NavItem> _sidebarBottomItems = [
  NavItem(
    label: 'Support',
    icon: Icons.help_outline,
    activeIcon: Icons.help,
    path: RoutePaths.support,
  ),
];

/// Responsive app shell that switches between
/// bottom nav (mobile), rail (tablet), and sidebar (web)
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenSize = context.screenSize;

    switch (screenSize) {
      case ScreenSize.mobile:
        return _MobileShell(child: child);
      case ScreenSize.tablet:
        return _TabletShell(child: child);
      case ScreenSize.web:
        return _WebShell(child: child);
    }
  }
}

/// ─── Mobile: Bottom Navigation Bar ──────────────────────
class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final navItems = _visibleMainNavItems(context);
    final currentIndex = _getCurrentIndex(context, navItems);

    return Scaffold(
      body: Column(
        children: [
          _MobileTopBar(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex.clamp(0, navItems.length - 1),
          onTap: (index) => _onNavTap(context, navItems[index].path),
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// ─── Tablet: Navigation Rail ────────────────────────────
class _TabletShell extends StatelessWidget {
  const _TabletShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final navItems = _visibleMainNavItems(context);
    final currentIndex = _getCurrentIndex(context, navItems);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex.clamp(0, navItems.length - 1),
            onDestinationSelected: (index) =>
                _onNavTap(context, navItems[index].path),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            destinations: navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Web: Persistent Sidebar ────────────────────────────
class _WebShell extends StatelessWidget {
  const _WebShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Web Sidebar (Figma-matching) ───────────────────────
class _WebSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // ── Logo ─────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      AppConstants.appSubtitle,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Quick Action Button ──────────
          // Hidden until the quick-action menu is built (kept, not removed).
          // Flip [_kShowQuickAction] to re-enable.
          if (_kShowQuickAction) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Quick action menu
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Quick Action'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (!_kShowQuickAction) const SizedBox(height: AppSpacing.xl),

          // ── Main Menu Label ──────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MAIN MENU', style: AppTextStyles.overline),
            ),
          ),

          // ── Main Nav Items (filtered by permissions) ─────
          ..._visibleNavItems(context, _sidebarMainItems).map(
            (item) => _SidebarNavItem(
              item: item,
              isActive: currentPath == item.path,
              onTap: () => _onNavTap(context, item.path),
            ),
          ),
          if (_hasAdminAccess(context))
            _SidebarNavItem(
              item: const NavItem(
                label: 'Admin Settings',
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                path: RoutePaths.settings,
              ),
              isActive: currentPath == RoutePaths.settings,
              onTap: () => _onNavTap(context, RoutePaths.settings),
            ),

          const Spacer(),

          // ── Add New Lead Button ──────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(RoutePaths.createLead),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Lead'),
              ),
            ),
          ),

          const Divider(),

          // ── Bottom Items ─────────────────
          ..._sidebarBottomItems.map(
            (item) => _SidebarNavItem(
              item: item,
              isActive: currentPath == item.path,
              onTap: () => _onNavTap(context, item.path),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Individual sidebar nav item
class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.navActiveBg
                  : _isHovered
                  ? AppColors.navHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  size: 20,
                  color: widget.isActive
                      ? AppColors.navActive
                      : AppColors.navInactive,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  widget.item.label,
                  style: widget.isActive
                      ? AppTextStyles.navItemActive
                      : AppTextStyles.navItem,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ─── Top Bar (Desktop/Tablet) ───────────────────────────
class _DesktopTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Global search
          GlobalSearchField(width: AppSpacing.searchBarWidth),
          const Spacer(),

          // Action buttons
          const NotificationBell(),
          const SizedBox(width: AppSpacing.sm),
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.search),
          //   tooltip: 'Global Search',
          // ),
          // const SizedBox(width: AppSpacing.sm),
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.add_circle_outline),
          //   tooltip: 'Quick Create',
          // ),
          const SizedBox(width: AppSpacing.md),

          // User avatar
          const _UserProfileDropdown(radius: 18),
        ],
      ),
    );
  }
}

/// ─── Mobile Top Bar ─────────────────────────────────────
class _MobileTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(AppConstants.appName, style: AppTextStyles.h4),
          const Spacer(),
          const NotificationBell(),
          const _UserProfileDropdown(radius: 16),
        ],
      ),
    );
  }
}

/// ─── Helpers ────────────────────────────────────────────

int _getCurrentIndex(BuildContext context, List<NavItem> navItems) {
  final currentPath = GoRouterState.of(context).matchedLocation;
  for (int i = 0; i < navItems.length; i++) {
    if (currentPath == navItems[i].path ||
        currentPath.startsWith('${navItems[i].path}/')) {
      return i;
    }
  }
  return 0;
}

void _onNavTap(BuildContext context, String path) {
  context.go(path);
}

/// Only users whose role can manage users/roles see the Admin Settings
/// entry point (top-level nav item, sidebar item, or "Settings" tab).
bool _hasAdminAccess(BuildContext context) {
  final user = _currentUser(context);
  if (user == null) return false;
  return user.hasPermission('users.manage') ||
      user.hasPermission('roles.manage');
}

/// The authenticated user, or null if not signed in.
User? _currentUser(BuildContext context) {
  final state = context.watch<AuthBloc>().state;
  return state is AuthAuthenticated ? state.user : null;
}

/// Filters [items] to those the current user is permitted to see, based on
/// the login-response permission codes on [User.permissions].
List<NavItem> _visibleNavItems(BuildContext context, List<NavItem> items) {
  final user = _currentUser(context);
  // Before auth resolves, only show items with no permission requirement.
  return items
      .where(
        (i) => user == null
            ? i.requiredPermissions.isEmpty
            : user.hasAnyPermission(i.requiredPermissions),
      )
      .toList();
}

List<NavItem> _visibleMainNavItems(BuildContext context) =>
    _visibleNavItems(context, _mainNavItems);

class _UserProfileDropdown extends StatelessWidget {
  final double radius;

  const _UserProfileDropdown({required this.radius});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final displayName = user?.name ?? 'Sarah Jenkins';
        final roleName = user?.role.name ?? 'Sales Team';

        final initials = displayName.isNotEmpty
            ? displayName
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase()
            : 'U';

        return PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            } else if (value == 'profile') {
              context.go(RoutePaths.profile);
            }
          },
          offset: const Offset(0, 48),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (user?.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.email,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text('View Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Log Out', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
