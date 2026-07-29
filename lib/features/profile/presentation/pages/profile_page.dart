import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../app/router/auth_notifier.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/usecases/profile_usecases.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _loading = true;
  String? _error;

  /// Notification preference toggles. Kept in-memory for this session — there
  /// is no preferences endpoint in the API yet, so these don't sync to the
  /// backend (the dialog says as much).
  final Map<String, bool> _notifPrefs = {
    'New lead assigned': true,
    'Deal stage changed': true,
    'Task overdue': true,
    'Weekly summary email': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await sl<FetchCurrentUserUseCase>()();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (user) => setState(() {
        _user = user;
        _error = null;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(context.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Profile', style: AppTextStyles.h1),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: _loading
                  ? const AppLoadingIndicator(message: 'Loading profile...')
                  : _error != null
                  ? ErrorState(message: _error!, onRetry: _load)
                  : _buildContent(context, _user!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    // Stretch so every card (avatar, account details, sessions...) fills the
    // full column width instead of shrink-wrapping to its own content — the
    // avatar card in particular has nothing inside forcing full width on its
    // own, which left a gap next to the narrower cards below it.
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AvatarCard(
          user: user,
          onChanged: (u) {
            setState(() => _user = u);
            // The shell's header avatar renders from the cached user, so nudge
            // AuthBloc to re-read it — otherwise the old photo lingers up
            // there after an upload or removal.
            context.read<AuthBloc>().add(const AuthCheckRequested());
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Account Details',
          child: Column(
            children: [
              _detailRow(
                'Account Created',
                user.createdAt != null
                    ? DateFormatter.displayDate(user.createdAt!)
                    : 'Unknown',
              ),
              const Divider(height: AppSpacing.xl),
              _detailRow(
                'Last Login',
                user.lastLoginAt != null
                    ? DateFormatter.relativeTime(user.lastLoginAt!)
                    : 'Unknown',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Active Sessions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sessionRow(
                context,
                icon: Icons.laptop_mac,
                title: 'This device',
                subtitle: 'Active now',
                onLogOut: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Remote session management is not available yet.',
                    ),
                  ),
                ),
                child: const Text('Log Out of All Other Sessions'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Notifications',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose which alerts you receive for leads, deals, and tasks.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showNotificationPreferences(context),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Manage Notification Preferences'),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Profile Information',
          child: _ProfileInfoForm(
            user: user,
            onSaved: (u) {
              setState(() => _user = u);
              context.read<AuthBloc>().add(const AuthCheckRequested());
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(title: 'Security', child: const _PasswordForm()),
      ],
    );

    return SingleChildScrollView(
      child: ResponsiveBuilder(
        mobile: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            const SizedBox(height: AppSpacing.xl),
            right,
          ],
        ),
        web: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 340, child: left),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(value, style: AppTextStyles.bodyMedium),
      ],
    );
  }

  Widget _sessionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onLogOut,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelMedium),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: AppColors.success),
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: onLogOut, child: const Text('Log out')),
      ],
    );
  }

  Future<void> _showNotificationPreferences(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (_) => _NotificationPreferencesDialog(initial: _notifPrefs),
    );
    if (result == null || !mounted) return;
    setState(() {
      _notifPrefs
        ..clear()
        ..addAll(result);
    });
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved on this device.'),
      ),
    );
  }
}

/// Local, in-memory notification preferences editor. There's no backend
/// endpoint for these yet, so the dialog notes that they aren't synced.
class _NotificationPreferencesDialog extends StatefulWidget {
  const _NotificationPreferencesDialog({required this.initial});
  final Map<String, bool> initial;

  @override
  State<_NotificationPreferencesDialog> createState() =>
      _NotificationPreferencesDialogState();
}

class _NotificationPreferencesDialogState
    extends State<_NotificationPreferencesDialog> {
  late final Map<String, bool> _prefs = Map<String, bool>.from(widget.initial);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Preferences'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in _prefs.entries)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.key, style: AppTextStyles.bodyMedium),
                value: entry.value,
                onChanged: (v) => setState(() => _prefs[entry.key] = v),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'These settings are stored on this device only — backend sync is coming soon.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_prefs),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AvatarCard extends StatefulWidget {
  const _AvatarCard({required this.user, required this.onChanged});
  final User user;

  /// Fired after a successful upload *or* removal, with the updated user.
  final ValueChanged<User> onChanged;

  @override
  State<_AvatarCard> createState() => _AvatarCardState();
}

class _AvatarCardState extends State<_AvatarCard> {
  bool _uploading = false;
  bool _removing = false;

  /// True while either avatar call is in flight — both buttons disable so a
  /// removal can't race an upload.
  bool get _busy => _uploading || _removing;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = (result != null && result.files.isNotEmpty)
        ? result.files.first
        : null;
    if (file?.bytes == null) return;
    setState(() => _uploading = true);
    final uploadResult = await sl<UploadAvatarUseCase>()(
      UploadAvatarParams(bytes: file!.bytes!, filename: file.name),
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    uploadResult.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload avatar: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      widget.onChanged,
    );
  }

  /// Deletes the avatar via `DELETE /users/me/avatar`. Confirms first, since
  /// the backend also removes the file from disk — this isn't undoable.
  Future<void> _confirmAndRemove() async {
    final messenger = ScaffoldMessenger.of(context);
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
    if (confirmed != true || !mounted) return;

    setState(() => _removing = true);
    final result = await sl<DeleteAvatarUseCase>()();
    if (!mounted) return;
    setState(() => _removing = false);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove photo: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (user) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile photo removed.')),
        );
        widget.onChanged(user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resolveMediaUrl(widget.user.avatarUrl);
    return SectionCard(
      // SectionCard left-anchors its body by default, which only matters now
      // that the card stretches to the column's full width — center this
      // one explicitly so the avatar/name/badge sit in the middle of it.
      child: Center(
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          widget.user.name.isNotEmpty
                              ? widget.user.name[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _busy ? null : _pickAndUpload,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: _uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              avatarUrl != null
                                  ? Icons.edit
                                  : Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.user.name, style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.user.role.name,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
            // Only offer removal when there's actually a photo to remove —
            // the endpoint is a no-op otherwise, so showing it would be a
            // button that appears to do nothing.
            if (avatarUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _busy ? null : _confirmAndRemove,
                icon: _removing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 16),
                label: Text(_removing ? 'Removing...' : 'Remove Photo'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoForm extends StatefulWidget {
  const _ProfileInfoForm({required this.user, required this.onSaved});
  final User user;
  final ValueChanged<User> onSaved;

  @override
  State<_ProfileInfoForm> createState() => _ProfileInfoFormState();
}

class _ProfileInfoFormState extends State<_ProfileInfoForm> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(
      text: widget.user.lastName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.user.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await sl<UpdateCurrentUserUseCase>()(
      UpdateCurrentUserParams(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated.'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved(user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          enabled: false,
          controller: TextEditingController(text: widget.user.email),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.lock_outline, size: 18),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone Number'),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

class _PasswordForm extends StatefulWidget {
  const _PasswordForm();

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _saving = false;

  double get _strength {
    final v = _newController.text;
    if (v.isEmpty) return 0;
    var score = 0;
    if (v.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v)) score++;
    if (RegExp(r'[!@#\$&*~%^()_+=\-]').hasMatch(v)) score++;
    return score / 4;
  }

  String get _strengthLabel {
    final s = _strength;
    if (s == 0) return '';
    if (s <= 0.25) return 'Weak';
    if (s <= 0.5) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong';
  }

  Color get _strengthColor {
    final s = _strength;
    if (s <= 0.25) return AppColors.error;
    if (s <= 0.5) return AppColors.warning;
    if (s <= 0.75) return AppColors.info;
    return AppColors.success;
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_newController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirmation do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_currentController.text.isEmpty || _newController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all password fields.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final authBloc = context.read<AuthBloc>();
    final result = await sl<ChangePasswordUseCase>()(
      ChangePasswordParams(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text(_cleanPasswordError(f.message)),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
        // Password changes invalidate the current session — force a fresh
        // sign-in.
        // Trigger the real logout so stored tokens are cleared (with a
        // best-effort server revoke). We deliberately do NOT await it: the
        // password change already invalidated the access token, so the
        // revoke call gets a 401 and drags the auth interceptor through a
        // refresh-retry round-trip that can stall on web — awaiting that
        // previously left the user stuck on this page.
        authBloc.add(const AuthLogoutRequested());
        // Flip the router's auth gate ourselves and navigate immediately, so
        // reaching /login doesn't depend on the AuthBloc emission landing
        // first. The bloc's own AuthUnauthenticated (once logout completes)
        // sets the same flag again — a harmless no-op.
        sl<AuthNotifier>().setAuthenticated(false);
        if (!mounted) return;
        context.go(RoutePaths.login);
      },
    );
  }

  /// Turns a raw backend/exception string into a short, user-facing message.
  String _cleanPasswordError(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('current password') ||
        m.contains('incorrect') ||
        m.contains('wrong')) {
      return 'Current password is incorrect.';
    }
    return 'Could not update password. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _currentController,
          obscureText: _obscureCurrent,
          decoration: InputDecoration(
            labelText: 'Current Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrent
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _newController,
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'New Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        if (_newController.text.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _strength,
                  color: _strengthColor,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _strengthLabel,
                style: AppTextStyles.caption.copyWith(color: _strengthColor),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _confirmController,
          obscureText: _obscureNew,
          decoration: const InputDecoration(labelText: 'Confirm New Password'),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Update Password'),
        ),
      ],
    );
  }
}
