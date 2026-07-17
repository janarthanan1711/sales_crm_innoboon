import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/deal.dart';

class CreateDealDialog extends StatefulWidget {
  final Deal? deal;

  const CreateDealDialog({super.key, this.deal});

  @override
  State<CreateDealDialog> createState() => _CreateDealDialogState();
}

class _CreateDealDialogState extends State<CreateDealDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _accountController;
  late final TextEditingController _valueController;
  late final TextEditingController _closeDateController;

  DealStage _stage = DealStage.qualifiedToBuy;
  String _owner = 'Sarah Jenkins (You)';
  String _contact = 'Sarah Jenkins (CTO)';

  bool get isEdit => widget.deal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deal?.name ?? '');
    _accountController = TextEditingController(
      text: widget.deal?.accountName ?? '',
    );
    _valueController = TextEditingController(
      text: widget.deal?.value.toStringAsFixed(2) ?? '',
    );
    _closeDateController = TextEditingController(
      text: widget.deal?.expectedCloseDate != null
          ? '${widget.deal!.expectedCloseDate!.month.toString().padLeft(2, '0')}/${widget.deal!.expectedCloseDate!.day.toString().padLeft(2, '0')}/${widget.deal!.expectedCloseDate!.year}'
          : '',
    );

    if (isEdit) {
      _stage = widget.deal!.stage;
      _owner = widget.deal!.owner;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _valueController.dispose();
    _closeDateController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      // Return true to indicate success
      debugPrint(
        'Deal Saved: ${_nameController.text}, Account: ${_accountController.text}, Value: ${_valueController.text}, Stage: $_stage, Close Date: ${_closeDateController.text}, Owner: $_owner, Contact: $_contact',
      );
      Navigator.of(context).pop(true);
    }
  }

  InputDecoration _inputDecoration(
    String hint, {
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildField(
    String label,
    bool required,
    Widget field, {
    Widget? rightAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: const Color(0xFF334155),
                ),
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Deal' : 'New Deal',
                  style: AppTextStyles.h2,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppColors.border),
            ),

            // Form
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
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          decoration: _inputDecoration(
                            'e.g., Acme Corp Q4 Expansion',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Associated Account',
                              true,
                              TextFormField(
                                controller: _accountController,
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                                decoration: _inputDecoration(
                                  'Search accounts...',
                                  prefix: const Icon(
                                    Icons.search,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                                decoration: _inputDecoration(
                                  '0.00',
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(
                                      left: 12,
                                      right: 8,
                                      top: 12,
                                      bottom: 12,
                                    ),
                                    child: Text(
                                      '\$',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 16,
                                      ),
                                    ),
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
                                items: DealStage.values
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.name),
                                      ),
                                    )
                                    .toList(),
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
                                  suffix: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'Owner',
                              false,
                              DropdownButtonFormField<String>(
                                value: _owner,
                                decoration: _inputDecoration(
                                  '',
                                  prefix: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Icon(
                                        Icons.person,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'Sarah Jenkins (You)',
                                    child: const Text('Sarah Jenkins (You)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'M. Chen',
                                    child: const Text('M. Chen'),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _owner = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildField(
                              'Contact',
                              true,
                              rightAction: InkWell(
                                onTap: () {},
                                child: Text(
                                  '+ Add Contact',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: _contact,
                                decoration: _inputDecoration(
                                  '',
                                  prefix: const Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'Sarah Jenkins (CTO)',
                                    child: const Text('Sarah Jenkins (CTO)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Alex',
                                    child: const Text('Alex'),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _contact = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F47C6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Save Deal'),
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
