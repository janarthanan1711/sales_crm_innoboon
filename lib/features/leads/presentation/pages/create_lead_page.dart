import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';

import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/usecases/lead_upsert_params.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/convert_lead_usecase.dart';
import '../../domain/usecases/log_lead_activity_usecase.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../../core/utils/formatters.dart';

class CreateLeadPage extends StatelessWidget {
  final Lead? lead;
  const CreateLeadPage({super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    return _CreateLeadView(lead: lead);
  }
}

class _CreateLeadView extends StatefulWidget {
  final Lead? lead;
  const _CreateLeadView({this.lead});

  @override
  State<_CreateLeadView> createState() => _CreateLeadViewState();
}

class _CreateLeadViewState extends State<_CreateLeadView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _domainController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _followUpNoteController = TextEditingController();

  late String _sourceLabel;
  late String _statusLabel;
  bool _submitting = false;

  /// True while the in-flight submit is the "Save & Convert" one, so only that
  /// button shows a spinner while both stay disabled.
  bool _submittingConvert = false;

  List<OwnerUser> _users = [];
  bool _loadingUsers = true;
  int? _selectedOwnerId;

  final List<_ContactDraftControllers> _additionalContactControllers = [];
  List<LeadActivity> _activities = [];

  bool get isEdit => widget.lead != null;

  @override
  void initState() {
    super.initState();
    _sourceLabel = AppConstants.leadSources.first;
    _statusLabel = AppConstants.leadStatuses.first;

    if (isEdit) {
      final l = widget.lead!;
      _firstNameController.text = l.firstName;
      _lastNameController.text = l.lastName ?? '';
      _companyController.text = l.company;
      _domainController.text = l.domain ?? '';
      _jobTitleController.text = l.jobTitle ?? '';
      _linkedinController.text = l.linkedinUrl ?? '';
      _emailController.text = l.email;
      _phoneController.text = l.phone ?? '';
      _followUpNoteController.text = l.followUpNote ?? '';

      _sourceLabel = labelForWireValue(leadSourceLabels, l.source);
      _statusLabel = labelForWireValue(leadStatusLabels, l.status);
      _selectedOwnerId = l.ownerId;
      _activities = List.from(l.activities ?? []);

      if (l.contacts != null) {
        // The backend returns the lead's own primary email/phone as a contact
        // row too. That's already shown in the Primary Email / Phone fields
        // above, so skip the first entry that just mirrors it — otherwise the
        // Additional Contacts section shows a phantom duplicate of the primary
        // email on every edit.
        final primaryEmail = l.email.trim().toLowerCase();
        final primaryPhone = (l.phone ?? '').trim();
        var skippedPrimary = false;
        for (final contact in l.contacts!) {
          final email = (contact.email ?? '').trim();
          final phone = (contact.phone ?? '').trim();
          if (email.isEmpty && phone.isEmpty) continue;

          final duplicatesPrimary =
              (email.isNotEmpty && email.toLowerCase() == primaryEmail) ||
              (email.isEmpty && phone.isNotEmpty && phone == primaryPhone);
          if (!skippedPrimary && duplicatesPrimary) {
            skippedPrimary = true;
            continue;
          }

          _additionalContactControllers.add(
            _ContactDraftControllers(
              email: contact.email,
              phone: contact.phone,
            ),
          );
        }
      }
    }

    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final result = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingUsers = false),
      (users) => setState(() {
        _users = users;
        _loadingUsers = false;
      }),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _domainController.dispose();
    _jobTitleController.dispose();
    _linkedinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _followUpNoteController.dispose();
    for (final c in _additionalContactControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Saves the form. With [convert] the new lead is immediately turned into an
  /// account — only offered on create, since an existing lead converts from its
  /// own detail page (and a converted one can't convert twice).
  Future<void> _onSubmit({bool convert = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Ask for the account's tier and owner *before* writing anything. Asking
    // afterwards would leave an unconverted lead behind whenever the user backs
    // out of the dialog — this way cancelling costs nothing.
    ({String tier, int? ownerId})? conversion;
    if (convert) {
      conversion = await _askConversionOptions();
      if (conversion == null || !mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitting = true;
      _submittingConvert = convert;
    });

    final params = LeadUpsertParams(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      company: _companyController.text.trim(),
      domain: _domainController.text.trim().isEmpty
          ? null
          : _domainController.text.trim(),
      jobTitle: _jobTitleController.text.trim().isEmpty
          ? null
          : _jobTitleController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      linkedinUrl: _linkedinController.text.trim().isEmpty
          ? null
          : _linkedinController.text.trim(),
      source: wireValueForLabel(leadSourceLabels, _sourceLabel) ?? 'other',
      status: wireValueForLabel(leadStatusLabels, _statusLabel),
      ownerId: _selectedOwnerId,
      followUpNote: _followUpNoteController.text.trim().isEmpty
          ? null
          : _followUpNoteController.text.trim(),
      additionalContacts: _additionalContactControllers
          .map(
            (c) => LeadContactDraft(
              email: c.email.text.trim().isEmpty ? null : c.email.text.trim(),
              phone: c.phone.text.trim().isEmpty ? null : c.phone.text.trim(),
            ),
          )
          .where((d) => !d.isEmpty)
          .toList(),
    );

    final result = isEdit
        ? await sl<UpdateLeadUseCase>()(
            UpdateLeadParams(id: widget.lead!.id, data: params),
          )
        : await sl<CreateLeadUseCase>()(params);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submittingConvert = false;
    });

    await result.fold(
      (failure) async {
        messenger.showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (lead) async {
        if (conversion != null) {
          await _convertCreatedLead(lead.id, conversion, messenger);
          return;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Lead updated successfully!'
                  : 'Lead created successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _safePop();
      },
    );
  }

  /// Second half of "Save & Convert": the lead already exists at this point, so
  /// a failure here is reported as a *partial* success and lands the user on
  /// the saved lead — telling them it failed outright would imply their typing
  /// was lost, and they can retry the conversion from the detail page.
  Future<void> _convertCreatedLead(
    int leadId,
    ({String tier, int? ownerId}) conversion,
    ScaffoldMessengerState messenger,
  ) async {
    final result = await sl<ConvertLeadToAccountUseCase>()(
      ConvertLeadParams(
        leadId: leadId,
        tier: conversion.tier,
        ownerId: conversion.ownerId,
      ),
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Lead saved, but conversion failed: ${failure.message}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('${RoutePaths.leads}/$leadId');
      },
      (accountId) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Lead created and converted to Account!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('${RoutePaths.accounts}/$accountId');
      },
    );
  }

  /// Tier + owner for the account the lead is about to become. Returns null if
  /// the user cancels, which aborts the whole save.
  Future<({String tier, int? ownerId})?> _askConversionOptions() {
    var tier = leadTierLabels.keys.first;
    var ownerId = _selectedOwnerId;

    return showDialog<({String tier, int? ownerId})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Convert to Account'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This lead will be saved and immediately converted into an '
                  'account.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Account Tier',
                  true,
                  DropdownButtonFormField<String>(
                    value: tier,
                    decoration: _inputDecoration(''),
                    items: leadTierLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => tier = v!),
                  ),
                ),
                const SizedBox(height: 16),
                _buildField(
                  'Account Owner',
                  true,
                  DropdownButtonFormField<int?>(
                    // Defaults to the Lead Owner already chosen on the form.
                    value: _users.any((u) => u.id == ownerId) ? ownerId : null,
                    decoration: _inputDecoration('Select owner'),
                    items: _users
                        .map(
                          (u) => DropdownMenuItem<int?>(
                            value: u.id,
                            child: Text(u.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => ownerId = v),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              // An account needs an owner, so this stays disabled until one is
              // picked — same rule as the detail page's convert dialog.
              onPressed: ownerId == null
                  ? null
                  : () => Navigator.pop(dialogContext, (
                      tier: tier,
                      ownerId: ownerId,
                    )),
              child: const Text('Save & Convert'),
            ),
          ],
        ),
      ),
    );
  }

  void _safePop() {
    // Reached via `context.go(...)`, so the stack can't always pop — fall
    // back to the leads list (or the edited lead's detail) so Cancel/Save
    // always navigates away instead of appearing to do nothing.
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else if (isEdit) {
      context.go('${RoutePaths.leads}/${widget.lead!.id}');
    } else {
      context.go(RoutePaths.leads);
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted),
      prefixIcon: prefix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildField(String label, bool required, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.fieldLabel,
            ),
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: AppColors.border),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(Widget child1, Widget child2, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [child1, const SizedBox(height: 16), child2],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 16),
        Expanded(child: child2),
      ],
    );
  }

  Widget _buildAdditionalContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _additionalContactControllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _buildResponsiveRow(
                    _buildField(
                      'Additional Email',
                      false,
                      TextFormField(
                        controller: _additionalContactControllers[i].email,
                        validator: (v) =>
                            v == null || v.isEmpty ? null : Validators.email(v),
                        decoration: _inputDecoration(
                          'alternate@acme.com',
                          prefix: Icon(
                            Icons.mail_outline,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    _buildField(
                      'Contact Phone',
                      false,
                      TextFormField(
                        controller: _additionalContactControllers[i].phone,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          '+1 (555) 000-0000',
                          prefix: Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    // Always stack email+phone vertically inside the narrow
                    // contact row so the remove button keeps its space.
                    true,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      final c = _additionalContactControllers.removeAt(i);
                      c.dispose();
                    });
                  },
                  icon: Icon(Icons.close, color: AppColors.textMuted),
                  tooltip: 'Remove contact',
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _additionalContactControllers.add(_ContactDraftControllers());
            });
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add another contact'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(bool isMobile) {
    return Column(
      children: [
        _buildCard('Basic Information', Icons.person_outline, [
          _buildResponsiveRow(
            _buildField(
              'First Name',
              true,
              TextFormField(
                controller: _firstNameController,
                validator: (v) => Validators.required(v, 'First name'),
                decoration: _inputDecoration('Jane'),
              ),
            ),
            _buildField(
              'Last Name',
              false,
              TextFormField(
                controller: _lastNameController,
                decoration: _inputDecoration('Doe'),
              ),
            ),
            isMobile,
          ),
          const SizedBox(height: 16),
          _buildField(
            'Company Name',
            true,
            TextFormField(
              controller: _companyController,
              validator: (v) => Validators.required(v, 'Company name'),
              decoration: _inputDecoration('Acme Corp'),
            ),
          ),
          const SizedBox(height: 16),
          _buildResponsiveRow(
            _buildField(
              'Company Domain',
              false,
              TextFormField(
                controller: _domainController,
                decoration: _inputDecoration(
                  'acme.com',
                  prefix: Icon(
                    Icons.link,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            _buildField(
              'Job Title',
              false,
              TextFormField(
                controller: _jobTitleController,
                decoration: _inputDecoration('VP of Sales'),
              ),
            ),
            isMobile,
          ),
          const SizedBox(height: 16),
          _buildField(
            'LinkedIn URL',
            false,
            TextFormField(
              controller: _linkedinController,
              decoration: _inputDecoration(
                'linkedin.com/in/arjumehta',
                prefix: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ]),
        _buildCard('Contact Details', Icons.contact_mail_outlined, [
          _buildResponsiveRow(
            _buildField(
              'Primary Email',
              true,
              TextFormField(
                controller: _emailController,
                validator: Validators.email,
                decoration: _inputDecoration(
                  'jane.doe@acme.com',
                  prefix: Icon(
                    Icons.mail_outline,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            _buildField(
              'Phone Number',
              false,
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration(
                  '+1 (555) 000-0000',
                  prefix: Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            isMobile,
          ),
          _buildAdditionalContacts(),
        ]),
        if (isEdit) _buildActivityLog(),
      ],
    );
  }

  Future<void> _showLogActivityDialog() async {
    final typeController = TextEditingController(
      text: leadActivityTypeLabels.keys.first,
    );
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Activity'),
              // Fixed width so a long note wraps instead of stretching the
              // dialog — AlertDialog otherwise sizes to the field's intrinsic
              // width. Matches the other Log Activity dialogs.
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      'Activity Type',
                      true,
                      DropdownButtonFormField<String>(
                        value: typeController.text,
                        decoration: _inputDecoration(''),
                        items: leadActivityTypeLabels.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => typeController.text = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Note',
                      true,
                      TextFormField(
                        controller: noteController,
                        maxLines: 4,
                        decoration: _inputDecoration('Activity details...'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (noteController.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Log Activity'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result == true) {
        final res = await sl<LogLeadActivityUseCase>()(
          LogLeadActivityParams(
            leadId: widget.lead!.id,
            type: typeController.text,
            note: noteController.text.trim(),
          ),
        );

        if (!mounted) return;
        res.fold(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          ),
          (activity) => setState(() => _activities.insert(0, activity)),
        );
      }
    });
  }

  IconData _iconForActivity(String? type) {
    switch (type) {
      case 'call':
        return Icons.phone;
      case 'meeting':
        return Icons.calendar_today;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.note;
    }
  }

  Widget _buildActivityLog() {
    return _buildCard('Activity', Icons.history, [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_activities.length}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _showLogActivityDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log Activity'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (_activities.isEmpty)
        Text(
          'No activities logged yet.',
          style: TextStyle(color: AppColors.textMuted),
        )
      else
        ..._activities.map((act) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    _iconForActivity(act.type),
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            labelForWireValue(leadActivityTypeLabels, act.type),
                            style: AppTextStyles.labelLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormatter.dateTime(act.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('"${act.note}"', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Logged by ${act.createdByName ?? 'User ${act.createdBy}'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
    ]);
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildCard('Classification', Icons.category_outlined, [
          _buildField(
            'Lead Source',
            false,
            DropdownButtonFormField<String>(
              value: _sourceLabel,
              decoration: _inputDecoration(''),
              items: AppConstants.leadSources
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _sourceLabel = v!),
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            'Lead Owner',
            false,
            _loadingUsers
                ? const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : DropdownButtonFormField<int?>(
                    value: _users.any((u) => u.id == _selectedOwnerId)
                        ? _selectedOwnerId
                        : null,
                    decoration: _inputDecoration(
                      'Select owner',
                      prefix: Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    items: _users
                        .map(
                          (u) => DropdownMenuItem<int?>(
                            value: u.id,
                            child: Text(u.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedOwnerId = v),
                  ),
          ),
          const SizedBox(height: 16),
          _buildField(
            'Status',
            false,
            DropdownButtonFormField<String>(
              value: _statusLabel,
              decoration: _inputDecoration(''),
              items: AppConstants.leadStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _statusLabel = v!),
            ),
          ),
        ]),
        _buildCard(
          isEdit ? 'Context' : 'Additional Context',
          Icons.notes_outlined,
          [
            _buildField(
              'Follow-up Note',
              false,
              TextFormField(
                controller: _followUpNoteController,
                maxLines: 4,
                decoration: _inputDecoration(
                  'Add relevant background information here...',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;
    final isMobile = width < 600;

    Widget headerActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: _submitting ? null : () => _safePop(),
          child: Text(
            'Cancel',
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Create only. An existing lead is converted from its own detail page,
        // and one that's already an account can't be converted twice.
        if (!isEdit) ...[
          ElevatedButton(
            onPressed: _submitting ? null : () => _onSubmit(convert: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            child: _submitting && _submittingConvert
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    // The full label doesn't fit a phone's action row.
                    isMobile ? 'Save & Convert' : 'Save & Convert to Account',
                    style: AppTextStyles.buttonMedium,
                  ),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: _submitting ? null : () => _onSubmit(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryButton,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
          ),
          child: _submitting && !_submittingConvert
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('Save', style: AppTextStyles.buttonMedium),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isEdit)
                        IconButton(
                          onPressed: () => _safePop(),
                          icon: Icon(
                            Icons.close,
                            size: 24,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (isEdit) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEdit ? 'Edit Lead' : 'New Lead',
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEdit
                        ? 'Review and update prospect information.'
                        : 'Create a new prospect profile to begin tracking.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: headerActions,
                  ),
                ],
              )
            else
              Row(
                children: [
                  if (isEdit)
                    IconButton(
                      onPressed: () => _safePop(),
                      icon: Icon(
                        Icons.close,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (isEdit) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? 'Edit Lead: ${widget.lead!.firstName} ${widget.lead!.lastName ?? ''}'
                              : 'New Lead',
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit
                              ? 'Review and update prospect information.'
                              : 'Create a new prospect profile to begin tracking.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  headerActions,
                ],
              ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Divider(color: AppColors.border),
            ),

            // Form
            Form(
              key: _formKey,
              child: isDesktop || isTablet
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildLeftColumn(isMobile)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildRightColumn()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeftColumn(isMobile),
                        _buildRightColumn(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Holds the email + phone controllers for one additional-contact row on the
/// lead form.
class _ContactDraftControllers {
  _ContactDraftControllers({String? email, String? phone})
    : email = TextEditingController(text: email),
      phone = TextEditingController(text: phone);

  final TextEditingController email;
  final TextEditingController phone;

  void dispose() {
    email.dispose();
    phone.dispose();
  }
}
