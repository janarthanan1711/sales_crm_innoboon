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
import '../../domain/entities/contact.dart';
import '../../domain/usecases/contact_usecases.dart';
import '../bloc/contact_detail_bloc.dart';

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
    return DefaultTabController(
      // Overview / Deals. "Notes" and "Activity" were both removed — neither
      // has a backing resource on the API (no contact notes, no contact
      // activity timeline), so both were placeholders.
      length: 2,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _breadcrumb(context, c),
            const SizedBox(height: AppSpacing.md),
            _HeaderCard(contact: c),
            const SizedBox(height: AppSpacing.lg),
            ResponsiveBuilder(
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ContactInfoCard(contact: c),
                  const SizedBox(height: AppSpacing.lg),
                  _MainPanel(state: state),
                ],
              ),
              web: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: _ContactInfoCard(contact: c)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _MainPanel(state: state)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breadcrumb(BuildContext context, Contact c) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/contacts'),
          child: Text(
            'Contacts',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            Icons.chevron_right,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        Flexible(
          child: Text(
            c.fullName,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (contact.jobTitle != null && contact.jobTitle!.isNotEmpty)
        contact.jobTitle!,
      if (contact.accountName != null) contact.accountName!,
    ];
    return SectionCard(
      child: Row(
        children: [
          InitialsAvatar(
            name: contact.fullName.isEmpty
                ? contact.firstName
                : contact.fullName,
            size: 56,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    Text(contact.fullName, style: AppTextStyles.h2),
                    if (contact.isPrimary) const _PrimaryPill(),
                    if (contact.tier != null) TierBadge(tier: contact.tier!),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join('  •  '),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (contact.ownerName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Owner: ${contact.ownerName}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          RecordExportButton(
            iconOnly: false,
            tooltip: 'Export this contact to Excel',
            fileName: 'contact_${contact.id}.xlsx',
            successMessage: 'Contact exported.',
            fetch: () => sl<ExportContactDetailUseCase>()(contact.id),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Contact Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Email', contact.email, email: contact.email),
          _row('Phone', contact.phone, phone: contact.phone),
          _row(
            'Alternate Phone',
            contact.alternatePhone,
            phone: contact.alternatePhone,
          ),
          _row('Social', contact.linkedinUrl, url: contact.linkedinUrl),
          _row('Account', contact.accountName),
          _row('Owner', contact.ownerName),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String? value, {
    String? email,
    String? url,
    String? phone,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final isLink = hasValue && (email != null || url != null || phone != null);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          if (isLink)
            LinkText(
              text: value,
              email: email,
              url: url,
              phone: phone,
              maxLines: 1,
            )
          else
            Text(hasValue ? value : '—', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _MainPanel extends StatelessWidget {
  const _MainPanel({required this.state});
  final ContactDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TabBar(
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Deals'),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Height-bounded so the nested tab views can lay out inside the outer
        // scroll view.
        SizedBox(
          height: 460,
          child: TabBarView(
            children: [
              _OverviewTab(state: state),
              _DealsTab(deals: state.deals),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state});
  final ContactDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final o = state.overview;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'About This Contact',
            child: Text(
              (o.about != null && o.about!.isNotEmpty)
                  ? o.about!
                  : 'No description added yet.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: (o.about != null && o.about!.isNotEmpty)
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Related Records',
            child: Row(
              children: [
                _stat('${o.dealCount}', 'Deals'),
                _stat(o.taskCount?.toString() ?? '—', 'Tasks'),
                _stat(o.logCount?.toString() ?? '—', 'Logs'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'Quick Stats',
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  o.lastActivity != null
                      ? 'Last activity ${DateFormatter.relativeTime(o.lastActivity!)}'
                      : 'No recent activity recorded',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.h2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.deals});
  final List<ContactDeal> deals;

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) {
      return const _EmptyTab(
        icon: Icons.handshake_outlined,
        message: 'This contact isn’t linked to any deals yet.',
      );
    }
    return ListView.separated(
      itemCount: deals.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final d = deals[index];
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
                    Text(
                      d.dealName,
                      style: AppTextStyles.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.expectedCloseDate != null)
                      Text(
                        'Closes ${DateFormatter.shortDate(d.expectedCloseDate!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                d.currency == 'USD'
                    ? '\$${d.value.toStringAsFixed(0)}'
                    : CurrencyFormatter.formatINR(d.value),
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
        );
      },
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
          const Icon(Icons.star, size: 12, color: AppColors.success),
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
