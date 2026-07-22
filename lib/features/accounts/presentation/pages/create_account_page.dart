import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../../leads/domain/entities/lead_enums.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../contacts/domain/usecases/contact_usecases.dart';
import '../../domain/usecases/create_account_usecase.dart';

/// Full-page "New Account" form (matches the accounts-flow Figma) — replaces
/// the old create dialog. Company info + classification + an optional
/// "Add Primary Contact now?" section.
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _companyController = TextEditingController();
  final _domainController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Primary contact (only used when the toggle is on).
  final _cFirstName = TextEditingController();
  final _cLastName = TextEditingController();
  final _cJobTitle = TextEditingController();
  final _cEmail = TextEditingController();
  final _cPhone = TextEditingController();

  String? _tier;
  String? _industry;
  int? _ownerId;
  bool _addPrimaryContact = false;
  bool _saving = false;

  List<OwnerUser> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final result = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    result.fold((_) {}, (u) => setState(() => _users = u));
  }

  @override
  void dispose() {
    for (final c in [
      _companyController,
      _domainController,
      _cityController,
      _descriptionController,
      _cFirstName,
      _cLastName,
      _cJobTitle,
      _cEmail,
      _cPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_companyController.text.trim().isEmpty) return 'Company name is required.';
    if (_domainController.text.trim().isEmpty) return 'Company domain is required.';
    if (_industry == null) return 'Please select an industry.';
    if (_tier == null) return 'Please select an account tier.';
    if (_addPrimaryContact) {
      if (_cFirstName.text.trim().isEmpty) return 'The primary contact needs a first name.';
      if (_cEmail.text.trim().isEmpty && _cPhone.text.trim().isEmpty) {
        return 'The primary contact needs an email or phone.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final error = _validate();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);

    String? val(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

    final result = await sl<CreateAccountUseCase>()(
      AccountUpsertParams(
        company: _companyController.text.trim(),
        domain: _domainController.text.trim(),
        tier: _tier!,
        ownerId: _ownerId,
        industry: _industry,
        city: val(_cityController),
        description: _descriptionController.text.trim(),
      ),
    );

    await result.fold(
      (f) async {
        if (!mounted) return;
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to create account: ${f.message}'), backgroundColor: AppColors.error),
        );
      },
      (account) async {
        // If requested, add the primary contact against the new account and
        // flag it primary (the create-contacts array can't set is_primary).
        if (_addPrimaryContact) {
          final accountId = int.tryParse(account.id);
          if (accountId != null) {
            await sl<UpsertAccountContactUseCase>()(
              UpsertAccountContactParams(
                accountId: accountId,
                firstName: val(_cFirstName),
                lastName: val(_cLastName),
                jobTitle: val(_cJobTitle),
                email: val(_cEmail),
                phone: val(_cPhone),
                isPrimary: true,
              ),
            );
          }
        }
        if (!mounted) return;
        context.go('/accounts/${account.id}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.isMobile ? AppSpacing.lg : AppSpacing.xxl;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, AppSpacing.lg, horizontal, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => context.go(RoutePaths.accounts),
                              child: Text('Accounts', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
                            ),
                            Text('New Account', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('New Account', style: AppTextStyles.h1),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: () => context.go(RoutePaths.accounts),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, AppSpacing.xxl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoBanner(),
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: 'Company Information',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Company Name', required: true),
                              TextField(
                                controller: _companyController,
                                decoration: const InputDecoration(hintText: 'e.g. Nexbridge Tech'),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _twoColumn(
                                context,
                                left: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel('Company Domain', required: true),
                                    TextField(
                                      controller: _domainController,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.language, size: 18),
                                        hintText: 'nexbridge.io',
                                      ),
                                    ),
                                  ],
                                ),
                                right: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel('Industry', required: true),
                                    DropdownButtonFormField<String>(
                                      initialValue: _industry,
                                      decoration: const InputDecoration(hintText: 'Select industry'),
                                      items: AppConstants.industries
                                          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                                          .toList(),
                                      onChanged: (v) => setState(() => _industry = v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel('Location (City)'),
                              TextField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                                  hintText: 'e.g. Coimbatore',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _FieldLabel('Description'),
                              TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(hintText: 'Enter company overview...'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SectionCard(
                          title: 'Classification & Ownership',
                          child: _twoColumn(
                            context,
                            left: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel('Account Tier', required: true),
                                DropdownButtonFormField<String>(
                                  initialValue: _tier,
                                  decoration: const InputDecoration(hintText: 'Select tier'),
                                  items: leadTierLabels.entries
                                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _tier = v),
                                ),
                              ],
                            ),
                            right: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel('Account Owner'),
                                DropdownButtonFormField<int>(
                                  initialValue: _ownerId,
                                  decoration: const InputDecoration(hintText: 'Select owner'),
                                  items: _users
                                      .map((u) => DropdownMenuItem(value: u.id, child: Text(u.displayName)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _ownerId = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PrimaryContactSection(
                          enabled: _addPrimaryContact,
                          onToggle: (v) => setState(() => _addPrimaryContact = v),
                          firstName: _cFirstName,
                          lastName: _cLastName,
                          jobTitle: _cJobTitle,
                          email: _cEmail,
                          phone: _cPhone,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _saving ? null : () => context.go(RoutePaths.accounts),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Save Account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _twoColumn(BuildContext context, {required Widget left, required Widget right}) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, const SizedBox(height: AppSpacing.md), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: right),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ensuring Industry and Tier are selected prevents data gaps in reporting.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          if (required)
            Text(' *', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
        ],
      ),
    );
  }
}

class _PrimaryContactSection extends StatelessWidget {
  const _PrimaryContactSection({
    required this.enabled,
    required this.onToggle,
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.email,
    required this.phone,
  });
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController jobTitle;
  final TextEditingController email;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Add Primary Contact now?', style: AppTextStyles.labelLarge)),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First Name *'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last Name'))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: jobTitle, decoration: const InputDecoration(labelText: 'Job Title')),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone'))),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Email or phone is required.', style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
