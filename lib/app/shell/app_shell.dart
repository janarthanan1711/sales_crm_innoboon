import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/media_url.dart';
import '../../core/constants/app_constants.dart';
import '../di/injector.dart';
import '../router/route_paths.dart';
import '../../features/auth/domain/usecases/profile_usecases.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
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
    requiredPermissions: [Perms.dashboardView],
  ),
  NavItem(
    label: 'Leads',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    path: RoutePaths.leads,
    requiredPermissions: ['leads.access', 'leads.view_all'],
  ),
  NavItem(
    label: 'Accounts',
    icon: Icons.business_outlined,
    activeIcon: Icons.business,
    path: RoutePaths.accounts,
    requiredPermissions: ['accounts.access', 'accounts.view_all'],
  ),
  NavItem(
    label: 'Deals',
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake,
    path: RoutePaths.deals,
    requiredPermissions: ['deals.access', 'deals.view_all'],
  ),
  NavItem(
    label: 'Contacts',
    icon: Icons.contacts_outlined,
    activeIcon: Icons.contacts,
    path: RoutePaths.contacts,
    requiredPermissions: ['contacts.access'],
  ),
  // Settings is intentionally NOT here — on mobile/tablet it lives in the
  // top app bar (see the settings action in the top bars), not the bottom
  // nav / rail.
];

/// Full sidebar items (web only)
const List<NavItem> _sidebarMainItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    path: RoutePaths.dashboard,
    requiredPermissions: [Perms.dashboardView],
  ),
  NavItem(
    label: 'Leads',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    path: RoutePaths.leads,
    requiredPermissions: ['leads.access', 'leads.view_all'],
  ),
  NavItem(
    label: 'Accounts',
    icon: Icons.business_outlined,
    activeIcon: Icons.business,
    path: RoutePaths.accounts,
    requiredPermissions: ['accounts.access', 'accounts.view_all'],
  ),
  NavItem(
    label: 'Deals',
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake,
    path: RoutePaths.deals,
    requiredPermissions: ['deals.access', 'deals.view_all'],
  ),
  NavItem(
    label: 'Contacts',
    icon: Icons.contacts_outlined,
    activeIcon: Icons.contacts,
    path: RoutePaths.contacts,
    requiredPermissions: ['contacts.access'],
  ),
  NavItem(
    label: 'Documents',
    icon: Icons.description_outlined,
    activeIcon: Icons.description,
    path: RoutePaths.documents,
  ),
];

const List<NavItem> _sidebarBottomItems = [
  // NavItem(
  //   label: 'Support',
  //   icon: Icons.help_outline,
  //   activeIcon: Icons.help,
  //   path: RoutePaths.support,
  // ),
];

/// Responsive app shell that switches between
/// bottom nav (mobile), rail (tablet), and sidebar (web)
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // One NotificationBloc for the whole shell, so the bell in the top bar and
    // the notifications page read and write the same state. They each used to
    // build their own instance from `sl` (a factory), which meant marking a
    // notification read updated the page's bloc while the bell kept rendering
    // the count it fetched at startup — it only looked right after a restart.
    return BlocProvider<NotificationBloc>(
      create: (_) =>
          sl<NotificationBloc>()..add(const NotificationLoadRequested()),
      child: Builder(
        builder: (context) {
          switch (context.screenSize) {
            case ScreenSize.mobile:
              return _MobileShell(child: child);
            case ScreenSize.tablet:
              return _TabletShell(child: child);
            case ScreenSize.web:
              return _WebShell(child: child);
          }
        },
      ),
    );
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
      // BottomNavigationBar asserts items.length >= 2. During the brief
      // window on restart before auth resolves no permission is held, so every
      // item filters out — omit the bar until there are ≥2.
      bottomNavigationBar: navItems.length < 2
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
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
          // NavigationRail asserts destinations.length >= 2 — skip the rail
          // during the pre-auth window when no item has cleared its gate yet.
          if (navItems.length >= 2) ...[
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
          ],
          Expanded(
            child: Column(
              children: [
                _DesktopTopBar(showSettingsAction: true),
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
          // Gated like the nav items above: a user who can't create leads
          // shouldn't be handed a shortcut into the create form.
          if (_canManageLeads(context))
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

/// Individual sidebar nav item.
///
/// Hover is left entirely to the [InkWell]. The previous version also tracked
/// it by hand in a [MouseRegion] and tinted the container, so two highlights
/// painted at once — the ink one unclipped and offset from the rounded
/// container, which is what read as the hover "glitch". [Material] below owns
/// the shape so the ink can't escape it.
class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      child: Material(
        color: isActive ? AppColors.navActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.navHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive ? AppColors.navActive : AppColors.navInactive,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  item.label,
                  style: isActive
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
  const _DesktopTopBar({this.showSettingsAction = false});

  /// Tablet has no sidebar Admin Settings entry (Settings was moved out of
  /// its nav rail), so it surfaces Settings here. Web keeps its sidebar entry
  /// and leaves this off.
  final bool showSettingsAction;

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
          if (showSettingsAction) const _SettingsAction(),
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
    return SafeArea(
      child: Container(
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
            const _SettingsAction(),
            const _UserProfileDropdown(radius: 16),
          ],
        ),
      ),
    );
  }
}

/// Admin Settings entry point for the mobile/tablet top bar — replaces the
/// bottom-nav / rail Settings tab. Only rendered for users who can manage
/// users or roles (same gate as the web sidebar's Admin Settings entry).
class _SettingsAction extends StatelessWidget {
  const _SettingsAction();

  @override
  Widget build(BuildContext context) {
    if (!_hasAdminAccess(context)) return const SizedBox.shrink();
    final active =
        GoRouterState.of(context).matchedLocation == RoutePaths.settings;
    return IconButton(
      tooltip: 'Admin Settings',
      icon: Icon(active ? Icons.settings : Icons.settings_outlined),
      color: active ? AppColors.primary : AppColors.textSecondary,
      onPressed: () => _onNavTap(context, RoutePaths.settings),
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

/// Whether the user may create leads. Same code the Leads nav item and the
/// leads-list create/import buttons gate on — `<module>.access` is this
/// backend's "view and manage own", so there's no finer-grained create code.
bool _canManageLeads(BuildContext context) =>
    _currentUser(context)?.hasPermission(Perms.leadsManage) ?? false;

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

        // Listens to [mediaVersion] rather than relying on this bloc state
        // alone: replacing the photo leaves every field of [User] identical
        // (the avatar URL is derived from the user id), so the re-read emits a
        // state equal to the current one and Bloc drops it — this builder
        // would never run again and the old photo would stay up.
        return ValueListenableBuilder<int>(
          valueListenable: mediaVersion,
          builder: (context, _, _) => _buildMenu(
            context,
            user,
            resolveMediaUrl(user?.avatarUrl, bustCache: true),
          ),
        );
      },
    );
  }

  Widget _buildMenu(BuildContext context, User? user, String? avatarUrl) {
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
        } else if (value == 'remove_photo') {
          _removePhoto(context);
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
        // Uploading/changing the photo lives on the Profile screen only — it
        // needs the surrounding context (preview, validation, save state) that
        // a header menu can't give it.
        if (avatarUrl != null)
          const PopupMenuItem(
            value: 'remove_photo',
            child: Row(
              children: [
                Icon(
                  Icons.hide_image_outlined,
                  size: 18,
                  color: AppColors.error,
                ),
                SizedBox(width: 8),
                Text('Remove Photo', style: TextStyle(color: AppColors.error)),
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
        // Show the uploaded photo globally; fall back to initials when
        // the user hasn't set one.
        backgroundImage: avatarUrl != null
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl != null
            ? null
            : Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _removePhoto(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text(
          'Your photo will be deleted and replaced with your initials. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await sl<DeleteAvatarUseCase>()();
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove photo: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile photo removed.')),
        );
        authBloc.add(const AuthCheckRequested());
      },
    );
  }
}
