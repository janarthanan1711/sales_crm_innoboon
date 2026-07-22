import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../app/di/injector.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/get_accounts_usecase.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../domain/usecases/create_deal_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';

/// Create/edit deal dialog — wired to the real `/deals` endpoints.
/// Returns the created/updated [Deal] via `Navigator.pop` on success.
class CreateDealDialog extends StatefulWidget {
  final Deal? deal;
  /// Preselects (and locks) the account when opened from an account's
  /// detail page — the account picker still needs the account's own name,
  /// since [Deal]/the API don't carry it.
  final Account? presetAccount;

  const CreateDealDialog({super.key, this.deal, this.presetAccount});

  @override
  State<CreateDealDialog> createState() => _CreateDealDialogState();
}

class _CreateDealDialogState extends State<CreateDealDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _closeDateController;

  DealStage _stage = DealStage.receivedRequirements;
  DateTime? _closeDate;
  Account? _selectedAccount;
  int? _selectedOwnerId;
  bool _saving = false;

  List<Account> _accounts = [];
  List<OwnerUser> _users = [];
  bool get isEdit => widget.deal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deal?.name ?? '');
    _valueController = TextEditingController(
      text: widget.deal != null ? widget.deal!.value.toStringAsFixed(2) : '',
    );
    _closeDate = widget.deal?.expectedCloseDate;
    _closeDateController = TextEditingController(
      text: _closeDate != null
          ? '${_closeDate!.month.toString().padLeft(2, '0')}/${_closeDate!.day.toString().padLeft(2, '0')}/${_closeDate!.year}'
          : '',
    );
    if (isEdit) {
      _stage = widget.deal!.stage;
      _selectedOwnerId = widget.deal!.ownerId;
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final accountsResult = await sl<GetAccountsUseCase>()(const GetAccountsParams(limit: 1000));
    final usersResult = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    setState(() {
      accountsResult.fold((_) {}, (page) => _accounts = page.items);
      usersResult.fold((_) {}, (u) => _users = u);
      if (widget.presetAccount != null) {
        _selectedAccount = widget.presetAccount;
      } else if (widget.deal != null) {
        final matches = _accounts.where((a) => a.id == widget.deal!.accountId);
        _selectedAccount = matches.isEmpty ? null : matches.first;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _closeDateController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account.')),
      );
      return;
    }
    setState(() => _saving = true);
    final value = double.tryParse(_valueController.text.trim()) ?? 0;

    final result = isEdit
        ? await sl<UpdateDealUseCase>()(
            UpdateDealParams(
              id: widget.deal!.id,
              dealName: _nameController.text.trim(),
              value: value,
              expectedCloseDate: _closeDate,
              stage: _stage,
              ownerId: _selectedOwnerId,
            ),
          )
        : await sl<CreateDealUseCase>()(
            CreateDealParams(
              dealName: _nameController.text.trim(),
              accountId: _selectedAccount!.id,
              value: value,
              expectedCloseDate: _closeDate,
              stage: _stage,
              ownerId: _selectedOwnerId,
            ),
          );

    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save deal: ${failure.message}'), backgroundColor: AppColors.error),
      ),
      (deal) => Navigator.of(context).pop(deal),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
    );
  }

  Widget _buildField(String label, bool required, Widget field, {Widget? rightAction}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: AppTextStyles.labelMedium.copyWith(color: const Color(0xFF334155)),
                children: [
                  if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
            if (rightAction != null) rightAction,
          ],
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isEdit ? 'Edit Deal' : 'New Deal', style: AppTextStyles.h2),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.border)),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildField(
                        'Deal Name',
                        true,
                        TextFormField(
                          controller: _nameController,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          decoration: _inputDecoration('e.g., Acme Corp Q4 Expansion'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Associated Account',
                              true,
                              DropdownButtonFormField<Account>(
                                value: _selectedAccount,
                                decoration: _inputDecoration('Select account'),
                                items: _accounts
                                    .map((a) => DropdownMenuItem(value: a, child: Text(a.companyName, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: widget.presetAccount != null
                                    ? null
                                    : (v) => setState(() => _selectedAccount = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              'Deal Value',
                              true,
                              TextFormField(
                                controller: _valueController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                decoration: _inputDecoration(
                                  '0.00',
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 12),
                                    child: Text('₹', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Stage',
                              false,
                              DropdownButtonFormField<DealStage>(
                                value: _stage,
                                decoration: _inputDecoration(''),
                                items: DealStage.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                                onChanged: (v) => setState(() => _stage = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              'Expected Close Date',
                              false,
                              TextFormField(
                                controller: _closeDateController,
                                readOnly: true,
                                decoration: _inputDecoration(
                                  'mm/dd/yyyy',
                                  suffix: const Icon(Icons.calendar_today, size: 18, color: AppColors.textMuted),
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _closeDate = date;
                                      _closeDateController.text =
                                          '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        'Owner',
                        false,
                        DropdownButtonFormField<int?>(
                          value: _selectedOwnerId,
                          decoration: _inputDecoration(
                            '',
                            prefix: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primaryLight,
                                child: Icon(Icons.person, size: 16, color: AppColors.primary),
                              ),
                            ),
                          ),
                          items: _users.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.displayName))).toList(),
                          onChanged: (v) => setState(() => _selectedOwnerId = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F47C6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Save Changes' : 'Save Deal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
