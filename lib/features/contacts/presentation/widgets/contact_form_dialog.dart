import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../app/di/injector.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../domain/entities/contact.dart';
import '../../domain/usecases/contact_usecases.dart';

/// Create-or-edit a contact against an account (`POST /accounts/{id}/contacts`).
/// The account picker is required, except for an originator: ticking "Is
/// Originator" disables it and saves the contact on its own (`POST /contacts`
/// / `PATCH /contacts/{id}`), keeping any account links it already has.
/// Pops `true` when a save succeeds.
class ContactFormDialog extends StatefulWidget {
  const ContactFormDialog({super.key, required this.accounts, this.existing});
  final List<Account> accounts;
  final Contact? existing;

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _jobTitle;
  late final TextEditingController _linkedin;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _altPhone;

  int? _accountId;
  bool _isPrimary = false;
  bool _isOriginator = false;
  bool _saving = false;

  bool get isEdit => widget.existing != null;

  /// Account.id is a String on the entity but the backend keys contacts by an
  /// int account_id — parse to the int the API expects, skipping any that
  /// don't parse.
  List<MapEntry<int, String>> get _accountOptions => widget.accounts
      .map((a) => MapEntry(int.tryParse(a.id) ?? -1, a.companyName))
      .where((e) => e.key != -1)
      .toList();

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _firstName = TextEditingController(text: c?.firstName ?? '');
    _lastName = TextEditingController(text: c?.lastName ?? '');
    _jobTitle = TextEditingController(text: c?.jobTitle ?? '');
    _linkedin = TextEditingController(text: c?.linkedinUrl ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _altPhone = TextEditingController(text: c?.alternatePhone ?? '');
    final opts = _accountOptions;
    // Only a new contact defaults to the first account. An existing one with
    // no account (an originator) must pick one explicitly if it's ever
    // un-flagged, rather than silently landing on whichever account is first.
    _accountId = c != null
        ? c.accountId
        : (opts.isNotEmpty ? opts.first.key : null);
    _isPrimary = c?.isPrimary ?? false;
    _isOriginator = c?.isOriginator ?? false;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _jobTitle.dispose();
    _linkedin.dispose();
    _email.dispose();
    _phone.dispose();
    _altPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isOriginator && _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select an associated account.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await sl<UpsertAccountContactUseCase>()(
      UpsertAccountContactParams(
        accountId: _isOriginator ? null : _accountId,
        contactId: widget.existing?.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        alternatePhone: _altPhone.text.trim().isEmpty
            ? null
            : _altPhone.text.trim(),
        jobTitle: _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
        linkedinUrl: _linkedin.text.trim().isEmpty
            ? null
            : _linkedin.text.trim(),
        isPrimary: _isOriginator ? null : _isPrimary,
        isOriginator: _isOriginator,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: AppColors.error),
      ),
      (_) => navigator.pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(isEdit ? 'Edit Contact' : 'Add Contact')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _isOriginator,
                  onChanged: (v) => setState(() => _isOriginator = v ?? false),
                  title: Text('Is Originator', style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    'Can be picked as the Originator of a deal. Originators '
                    'don\'t need an associated account.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('BASIC INFORMATION', style: AppTextStyles.overline),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        validator: (v) => Validators.required(v, 'First name'),
                        decoration: _dec('First Name *'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        decoration: _dec('Last Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _jobTitle,
                  decoration: _dec('Job Title'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _linkedin,
                  decoration: _dec('LinkedIn URL'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('CONTACT DETAILS', style: AppTextStyles.overline),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  // POST /contacts (originators) requires an email.
                  validator: (v) => v == null || v.isEmpty
                      ? (_isOriginator ? 'Email is required' : null)
                      : Validators.email(v),
                  decoration: _dec(
                    _isOriginator ? 'Primary Email *' : 'Primary Email',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration: _dec('Phone Number'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _altPhone,
                        decoration: _dec('Alternate Phone'),
                      ),
                    ),
                  ],
                ),
                // Originators don't belong to an account, so the account
                // section is hidden (existing links are left untouched).
                if (!_isOriginator) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  Text('ACCOUNT ASSOCIATION', style: AppTextStyles.overline),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue:
                        _accountOptions.any((e) => e.key == _accountId)
                        ? _accountId
                        : null,
                    decoration: _dec('Associated Account *'),
                    items: _accountOptions
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _accountId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _isPrimary,
                    onChanged: (v) => setState(() => _isPrimary = v ?? false),
                    title: Text(
                      'Set as Primary Contact',
                      style: AppTextStyles.bodyMedium,
                    ),
                    subtitle: Text(
                      'Only one primary contact allowed per account.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? 'Save Contact' : 'Add Contact'),
        ),
      ],
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
