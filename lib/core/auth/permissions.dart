import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Canonical permission-code constants used for UI gating.
///
/// This backend models permissions coarsely: `<module>.access` grants
/// "view and manage own" (i.e. create / edit / delete), while
/// `<module>.view_all` only widens visibility. So create/edit/delete actions
/// are gated on `.access`, not on non-existent fine-grained codes.
class Perms {
  Perms._();

  static const String leadsManage = 'leads.access';
  static const String leadsViewAll = 'leads.view_all';

  static const String dealsManage = 'deals.access';
  static const String dealsViewAll = 'deals.view_all';

  static const String accountsManage = 'accounts.access';
  static const String accountsViewAll = 'accounts.view_all';

  // Contacts has no `view_all` counterpart — `contacts.access` is the only
  // contacts code the backend issues.
  static const String contactsManage = 'contacts.access';

  static const String usersManage = 'users.manage';
  static const String rolesManage = 'roles.manage';
}

/// Reads the authenticated user's permissions from [AuthBloc] to gate UI.
extension PermissionContext on BuildContext {
  /// The signed-in user, or null before auth resolves.
  User? get currentUser {
    final state = read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  /// Watching variant — rebuilds the caller when the auth state changes.
  User? get watchUser {
    final state = watch<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  /// True if the current user holds [code]. Defaults to false when signed out.
  bool can(String code) => currentUser?.hasPermission(code) ?? false;
}
