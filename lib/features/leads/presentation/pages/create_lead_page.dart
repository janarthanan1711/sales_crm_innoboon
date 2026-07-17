import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_hub/features/leads/presentation/bloc/leads_list_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';

import '../../domain/entities/lead.dart';

class CreateLeadPage extends StatelessWidget {
  final Lead? lead;
  const CreateLeadPage({super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LeadsListBloc>(),
      child: _CreateLeadView(lead: lead),
    );
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
  final _notesController = TextEditingController();

  String _source = AppConstants.leadSources.first;
  String _owner = 'Sarah Jenkins';
  String _status = 'New';

  bool get isEdit => widget.lead != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final names = widget.lead!.contactName.split(' ');
      _firstNameController.text = names.first;
      if (names.length > 1) {
        _lastNameController.text = names.sublist(1).join(' ');
      }
      _companyController.text = widget.lead!.companyName;
      _domainController.text = widget.lead!.website ?? '';
      _emailController.text = widget.lead!.email;
      _phoneController.text = widget.lead!.phone ?? '';
      _notesController.text = widget.lead!.notes ?? '';

      _source = widget.lead!.source;
      _owner = widget.lead!.owner ?? 'Sarah Jenkins';
      _status = widget.lead!.status;
    }
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
    _notesController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
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
    }
  }

  void _safePop() {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: prefix,
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

  Widget _buildField(String label, bool required, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Padding(
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
              true,
              TextFormField(
                controller: _lastNameController,
                validator: (v) => Validators.required(v, 'Last name'),
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
              true,
              TextFormField(
                controller: _domainController,
                decoration: _inputDecoration(
                  'https://acme.com',
                  prefix: const Icon(
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
                prefix: const Icon(
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
                  prefix: const Icon(
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
                  prefix: const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            isMobile,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '+ Add another email',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildCard('Classification', Icons.category_outlined, [
          _buildField(
            'Lead Source',
            false,
            DropdownButtonFormField<String>(
              value: _source,
              decoration: _inputDecoration(''),
              items: AppConstants.leadSources
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _source = v!),
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            'Lead Owner',
            false,
            DropdownButtonFormField<String>(
              value: _owner,
              decoration: _inputDecoration(
                '',
                prefix: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Sarah Jenkins',
                  child: Text('Sarah Jenkins (Me)'),
                ),
                DropdownMenuItem(value: 'Karthick', child: Text('Karthick')),
              ],
              onChanged: (v) => setState(() => _owner = v!),
            ),
          ),
          const SizedBox(height: 16),
          _buildField(
            'Status',
            false,
            DropdownButtonFormField<String>(
              value: _status,
              decoration: _inputDecoration(''),
              items: AppConstants.leadStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ),
        ]),
        _buildCard(
          isEdit ? 'Context' : 'Additional Context',
          Icons.notes_outlined,
          [
            _buildField(
              isEdit ? 'Notes' : 'Notes / Comments',
              false,
              TextFormField(
                controller: _notesController,
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
          onPressed: () => _safePop(),
          child: Text(
            'Cancel',
            style: AppTextStyles.buttonMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (!isEdit) ...[
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            child: Text(
              isMobile ? 'Convert' : 'Save & Convert to Account',
              style: AppTextStyles.buttonMedium,
            ),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton(
          onPressed: _onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F47C6),
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
          child: Text('Save', style: AppTextStyles.buttonMedium),
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
                          icon: const Icon(
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
                      icon: const Icon(
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
                              ? 'Edit Lead: ${widget.lead!.contactName}'
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
            const Padding(
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
