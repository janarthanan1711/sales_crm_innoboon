import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../roles/domain/entities/permission.dart';
import '../../../roles/domain/entities/role.dart';
import '../../../roles/domain/usecases/role_usecases.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../users/domain/usecases/create_user_usecase.dart';
import '../../../users/domain/usecases/delete_user_usecase.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Settings', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'Manage your organization, team members, and global configurations.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.labelLarge,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Roles'),
              Tab(text: 'Configuration'),
              Tab(text: 'Audit Log'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _UsersTab(),
                _RolesTab(),
                _ComingSoonTab(message: 'Global configuration options aren\'t available yet.'),
                _ComingSoonTab(message: 'Audit logging isn\'t available yet.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Users tab
// ─────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<OwnerUser> _users = [];
  List<Role> _roles = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int? _roleFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rolesResult = await sl<ListRolesUseCase>()();
    final usersResult = await sl<GetUsersUseCase>()(
      roleId: _roleFilter,
      status: _statusFilter,
      search: _search.isEmpty ? null : _search,
    );
    if (!mounted) return;
    rolesResult.fold((_) {}, (r) => _roles = r);
    usersResult.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (u) => setState(() {
        _users = u;
        _error = null;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 280,
                child: AppSearchField(
                  hintText: 'Filter by name or email...',
                  onChanged: (v) {
                    _search = v;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Dropdown<int?>(
                label: 'All Roles',
                value: _roleFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                  ..._roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                ],
                onChanged: (v) {
                  setState(() => _roleFilter = v);
                  _load();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _Dropdown<String?>(
                label: 'All Status',
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'invited', child: Text('Invited')),
                  DropdownMenuItem(value: 'deactivated', child: Text('Deactivated')),
                ],
                onChanged: (v) {
                  setState(() => _statusFilter = v);
                  _load();
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showInviteDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Invite User'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator(message: 'Loading users...')
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _users.isEmpty
                        ? const EmptyState(icon: Icons.people_outline, title: 'No users found')
                        : _UsersTable(users: _users, onChanged: _load),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    int? roleId = _roles.isNotEmpty ? _roles.first.id : null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Invite User'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: AppSpacing.md),
                    TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
                    const SizedBox(height: AppSpacing.md),
                    TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int?>(
                      value: roleId,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: _roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                      onChanged: (v) => setState(() => roleId = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.trim().isEmpty || roleId == null) return;
                    final result = await sl<CreateUserUseCase>()(
                      CreateUserParams(
                        email: emailController.text.trim(),
                        firstName: firstNameController.text.trim(),
                        lastName: lastNameController.text.trim(),
                        roleId: roleId!,
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    result.fold(
                      (f) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to invite user: ${f.message}'), backgroundColor: AppColors.error),
                      ),
                      (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation sent.'), backgroundColor: AppColors.success),
                        );
                        _load();
                      },
                    );
                  },
                  child: const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.onChanged});
  final List<OwnerUser> users;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                _header('NAME', flex: 3),
                _header('EMAIL', flex: 3),
                _header('ROLE', flex: 2),
                _header('STATUS', flex: 2),
                _header('LAST LOGIN', flex: 2),
                _header('', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _UserRow(user: users[index], onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String label, {int flex = 1}) => Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onChanged});
  final OwnerUser user;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InitialsAvatar(name: user.displayName, size: 32),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(user.displayName, style: AppTextStyles.labelLarge, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(user.email, style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.center,
              child: Text(user.role.name.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ),
          ),
          Expanded(flex: 2, child: _statusBadge(user.status)),
          Expanded(
            flex: 2,
            child: Text(
              user.lastLoginAt != null ? DateFormatter.relativeTime(user.lastLoginAt!) : 'Never',
              style: AppTextStyles.tableCell,
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Deactivate user?'),
                      content: Text('${user.displayName} will lose access immediately.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Deactivate', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final result = await sl<DeleteUserUseCase>()(user.id);
                  result.fold(
                    (f) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to deactivate: ${f.message}'), backgroundColor: AppColors.error),
                    ),
                    (_) => onChanged(),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppColors.success;
        break;
      case 'invited':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(status[0].toUpperCase() + status.substring(1), style: AppTextStyles.bodySmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Roles tab
// ─────────────────────────────────────────────────────────

class _RolesTab extends StatefulWidget {
  const _RolesTab();

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  List<Role> _roles = [];
  List<Permission> _permissions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rolesResult = await sl<ListRolesUseCase>()();
    final permsResult = await sl<ListPermissionsUseCase>()();
    if (!mounted) return;
    permsResult.fold((_) {}, (p) => _permissions = p);
    rolesResult.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (r) => setState(() {
        _roles = r;
        _error = null;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showRoleDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Role'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator(message: 'Loading roles...')
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : ListView.separated(
                        itemCount: _roles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(role.name, style: AppTextStyles.labelLarge),
                                      Text(
                                        role.description.isEmpty ? '${role.permissions.length} permissions' : role.description,
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showRoleDialog(context, role: role),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  onPressed: () => _confirmDelete(context, role),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Role role) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text('This cannot be undone. "${role.name}" will no longer be assignable.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await sl<DeleteRoleUseCase>()(role.id);
              result.fold(
                (f) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete role: ${f.message}'), backgroundColor: AppColors.error),
                ),
                (_) => _load(),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, {Role? role}) {
    final nameController = TextEditingController(text: role?.name ?? '');
    final descriptionController = TextEditingController(text: role?.description ?? '');
    final selected = <int>{...?role?.permissions.map((p) => p.id)};
    final permissionsByModule = <String, List<Permission>>{};
    for (final p in _permissions) {
      permissionsByModule.putIfAbsent(p.module, () => []).add(p);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(role == null ? 'New Role' : 'Edit Role'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Role Name')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Permissions', style: AppTextStyles.labelMedium),
                      for (final module in permissionsByModule.keys) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(module.toUpperCase(), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ...permissionsByModule[module]!.map((p) => CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(p.label, style: AppTextStyles.bodyMedium),
                              value: selected.contains(p.id),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  selected.add(p.id);
                                } else {
                                  selected.remove(p.id);
                                }
                              }),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    final result = role == null
                        ? await sl<CreateRoleUseCase>()(
                            CreateRoleParams(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              permissionIds: selected.toList(),
                            ),
                          )
                        : await sl<UpdateRoleUseCase>()(
                            UpdateRoleParams(
                              id: role.id,
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              permissionIds: selected.toList(),
                            ),
                          );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    result.fold(
                      (f) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save role: ${f.message}'), backgroundColor: AppColors.error),
                      ),
                      (_) => _load(),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: (v) {
            if (v != null || items.any((i) => i.value == null)) onChanged(v as T);
          },
          hint: Text(label, style: AppTextStyles.labelMedium),
        ),
      ),
    );
  }
}
