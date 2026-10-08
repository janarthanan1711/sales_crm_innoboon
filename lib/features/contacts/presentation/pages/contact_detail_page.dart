import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/link_launcher.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/widgets/record_export_button.dart';
import '../../../../app/di/injector.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../domain/entities/contact.dart';
import '../../domain/usecases/contact_usecases.dart';
import '../bloc/contact_detail_bloc.dart';
import '../widgets/contact_form_dialog.dart';
import '../widgets/originator_badge.dart';
import '../../../accounts/domain/usecases/get_accounts_usecase.dart';

class ContactDetailPage extends StatelessWidget {
  const ContactDetailPage({super.key, required this.contactId});
  final String contactId;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(contactId) ?? 0;
    return BlocProvider(
      create: (_) =>
          sl<ContactDetailBloc>()..add(ContactDetailLoadRequested(id)),
      child: const _ContactDetailView(),
    );
  }
}

class _ContactDetailView extends StatelessWidget {
  const _ContactDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ContactDetailBloc, ContactDetailState>(
        builder: (context, state) {
          if (state is ContactDetailLoading) {
            return const AppLoadingIndicator(message: 'Loading contact...');
          }
          if (state is ContactDetailError) {
            return ErrorState(message: state.message, onRetry: () {});
          }
          if (state is ContactDetailLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ContactDetailLoaded state) {
    final c = state.overview.contact;
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breadcrumb(context, c, state.overview.createdAt),
          const SizedBox(height: AppSpacing.lg),
          _HeaderCard(
            contact: c,
            dealCount: state.deals.length,
            createdAt: state.overview.createdAt,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ContactInfoCard(
            contact: c,
            createdAt: state.overview.createdAt,
            createdByName: state.overview.createdByName,
          ),
          const SizedBox(height: AppSpacing.xl),
          _DealsSection(deals: state.deals),
        ],
      ),
    );
  }

  Widget _breadcrumb(BuildContext context, Contact c, DateTime? createdAt) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/contacts'),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Back to Contacts',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          '  /  ',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            c.fullName,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        if (!context.isMobile)
          Text(
            [
              'CT-${c.id}',
              if (createdAt != null)
                'Created ${DateFormatter.displayDate(createdAt)}',
            ].join('  •  '),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.contact,
    required this.dealCount,
    this.createdAt,
  });
  final Contact contact;
  final int dealCount;
  final DateTime? createdAt;

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<ContactDetailBloc>();
    final accounts = (await sl<GetAccountsUseCase>()(
      const GetAccountsParams(limit: 1000),
    )).fold((_) => const <Account>[], (page) => page.items);
    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ContactFormDialog(accounts: accounts, existing: contact),
    );
    if (saved == true) bloc.add(ContactDetailLoadRequested(contact.id));
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (contact.jobTitle != null && contact.jobTitle!.isNotEmpty)
        contact.jobTitle!,
      if (contact.accountName != null) contact.accountName!,
    ];
    final email = contact.email;
    final phone = contact.phone;

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RecordExportButton(
          iconOnly: false,
          tooltip: 'Export this contact to Excel',
          fileName: 'contact_${contact.id}.xlsx',
          successMessage: 'Contact exported.',
          fetch: () => sl<ExportContactDetailUseCase>()(contact.id),
        ),
        ElevatedButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit Contact'),
        ),
      ],
    );

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InitialsAvatar(
          name: contact.fullName.isEmpty ? contact.firstName : contact.fullName,
          size: 64,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contact.isPrimary ||
                  contact.isOriginator ||
                  contact.tier != null) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (contact.isPrimary) const _PrimaryPill(),
                    if (contact.isOriginator)
                      const OriginatorBadge(compact: false),
                    if (contact.tier != null) TierBadge(tier: contact.tier!),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(contact.fullName, style: AppTextStyles.h1),
              if (subtitleParts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitleParts.join('  •  '),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if ((email != null && email.isNotEmpty) ||
                  (phone != null && phone.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (email != null && email.isNotEmpty)
                      _contactLine(
                        Icons.mail_outline,
                        LinkText(text: email, email: email, maxLines: 1),
                      ),
                    if (phone != null && phone.isNotEmpty)
                      _contactLine(
                        Icons.phone_outlined,
                        LinkText(text: phone, phone: phone, maxLines: 1),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    final stats = Wrap(
      spacing: AppSpacing.huge,
      runSpacing: AppSpacing.lg,
      children: [
        MetaStat(label: 'Account', value: Text(contact.accountName ?? '—')),
        MetaStat(
          label: 'Owner',
          value: contact.ownerName == null
              ? const Text('—')
              : OwnerChip(name: contact.ownerName!),
        ),
        MetaStat(label: 'Linked deals', value: Text('$dealCount')),
        MetaStat(
          label: 'Created on',
          value: Text(
            createdAt == null ? '—' : DateFormatter.displayDate(createdAt!),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        context.isMobile ? AppSpacing.lg : AppSpacing.xxl,
      ),
      decoration: appCardDecoration(radius: AppSpacing.cardRadiusLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          context.isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: AppSpacing.lg),
                    actions,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: AppSpacing.lg),
                    actions,
                  ],
                ),
          const SizedBox(height: AppSpacing.xl),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.xl),
          stats,
        ],
      ),
    );
  }

  Widget _contactLine(IconData icon, Widget child) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Flexible(child: child),
      ],
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({
    required this.contact,
    this.createdAt,
    this.createdByName,
  });
  final Contact contact;

  /// Creation audit, from `GET /contacts/{id}/overview` rather than the contact
  /// itself. Both are null-tolerant: the row is omitted without [createdAt],
  /// and the "by …" line only appears when the API knows who created it (it
  /// returns null for records created outside the audit-logged path).
  final DateTime? createdAt;
  final String? createdByName;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Contact Information',
      child: InfoGrid(
        items: [
          _item('Email', contact.email, email: contact.email),
          _item('Phone', contact.phone, phone: contact.phone),
          _item(
            'Alternate Phone',
            contact.alternatePhone,
            phone: contact.alternatePhone,
          ),
          _item('Social', contact.linkedinUrl, url: contact.linkedinUrl),
          _item('Account', contact.accountName),
          _item('Owner', contact.ownerName),
          if (createdAt != null)
            _item(
              'Created On',
              DateFormatter.shortDate(createdAt!),
              subtitle: createdByName != null && createdByName!.isNotEmpty
                  ? 'by $createdByName'
                  : null,
            ),
        ],
      ),
    );
  }

  (String, Widget) _item(
    String label,
    String? value, {
    String? email,
    String? url,
    String? phone,
    String? subtitle,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final isLink = hasValue && (email != null || url != null || phone != null);
    return (
      label,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLink)
            LinkText(
              text: value,
              email: email,
              url: url,
              phone: phone,
              maxLines: 1,
            )
          else
            Text(hasValue ? value : '—'),
          if (subtitle != null)
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

// Deals is the only sub-section (Overview was removed), so there's no
// TabBar — just one card listing the linked deals.
class _DealsSection extends StatelessWidget {
  const _DealsSection({required this.deals});
  final List<ContactDeal> deals;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Deals',
      trailing: Text(
        '${deals.length} linked',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      padding: EdgeInsets.zero,
      child: deals.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
              child: _EmptyTab(
                icon: Icons.handshake_outlined,
                message: 'This contact isn’t linked to any deals yet.',
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < deals.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppColors.borderLight),
                  _dealRow(deals[i]),
                ],
              ],
            ),
    );
  }

  Widget _dealRow(ContactDeal d) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: TwoLineCell(
              leading: InitialsAvatar(name: d.dealName, size: 32),
              title: d.dealName,
              subtitle: d.expectedCloseDate == null
                  ? null
                  : 'Closes ${DateFormatter.shortDate(d.expectedCloseDate!)}',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            d.currency == 'USD'
                ? '\$${d.value.toStringAsFixed(0)}'
                : CurrencyFormatter.formatINR(d.value),
            style: AppTextStyles.tableCell.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            'Primary Contact',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
