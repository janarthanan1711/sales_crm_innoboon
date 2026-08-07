import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../app/router/route_paths.dart';
import '../bloc/notification_bloc.dart';

/// Top-bar bell. Reads the shell-scoped [NotificationBloc] — the same instance
/// the notifications page acts on — so the badge tracks reads immediately.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      // A reload passes through Loading, which carries no count. Rebuilding on
      // it would blank the badge and pop it back a moment later every time the
      // page refilters, so hold the last known count until one arrives.
      buildWhen: (_, next) => next is NotificationLoaded,
      builder: (context, state) {
        final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              color: AppColors.textPrimary,
              tooltip: 'Notifications',
              onPressed: () => context.go(RoutePaths.notifications),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
