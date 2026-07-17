import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_detail_bloc.dart';

class LeadDetailPage extends StatelessWidget {
  const LeadDetailPage({super.key, required this.leadId});
  final String leadId;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(leadId) ?? 0;
    return BlocProvider(
      create: (_) => sl<LeadDetailBloc>()..add(LeadDetailLoadRequested(id)),
      child: _LeadDetailView(leadId: id),
    );
  }
}

class _LeadDetailView extends StatelessWidget {
  const _LeadDetailView({required this.leadId});
  final int leadId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<LeadDetailBloc, LeadDetailState>(
        listener: (context, state) {
          if (state is LeadDetailConverted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead converted to Account successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/accounts/${state.accountId}');
          }
          if (state is LeadDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead deleted.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(RoutePaths.leads);
          }
        },
        builder: (context, state) {
          if (state is LeadDetailLoading) {
            return const AppLoadingIndicator(message: 'Loading lead...');
          }
          if (state is LeadDetailError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<LeadDetailBloc>().add(
                LeadDetailLoadRequested(leadId),
              ),
            );
          }
          if (state is LeadDetailLoaded) {
            final lead = state.lead;
            final contactName = [
              lead.firstName,
              lead.lastName,
            ].where((s) => s != null && s.isNotEmpty).join(' ');

            return SingleChildScrollView(
              padding: EdgeInsets.all(context.isMobile ? 16.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/leads'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lead.company, style: AppTextStyles.h1),
                            Text(
                              contactName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge.leadStatus(
                        labelForWireValue(leadStatusLabels, lead.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Action buttons
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push(
                            RoutePaths.editLead.replaceFirst(
                              ':id',
                              '${lead.id}',
                            ),
                            extra: lead,
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Lead'),
                      ),
                      if (!lead.isConverted)
                        ElevatedButton.icon(
                          onPressed: () => _showConvertDialog(context, lead.id),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Convert to Account'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, lead.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Info cards
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      _infoCard('Contact Information', [
                        _infoRow('Email', lead.email),
                        _infoRow('Phone', lead.phone ?? 'Not provided'),
                        _infoRow('Company', lead.company),
                        _infoRow('Job Title', lead.jobTitle ?? 'Not set'),
                      ]),
                      _infoCard('Lead Details', [
                        _infoRow(
                          'Source',
                          labelForWireValue(leadSourceLabels, lead.source),
                        ),
                        _infoRow('Domain', lead.domain ?? 'Not set'),
                        _infoRow('LinkedIn', lead.linkedinUrl ?? 'Not set'),
                        _infoRow('Owner', lead.ownerName ?? 'Unassigned'),
                      ]),
                      _infoCard('Timeline', [
                        _infoRow(
                          'Last Updated',
                          DateFormatter.shortDate(lead.updatedAt),
                        ),
                        _infoRow(
                          'Next Follow-up',
                          lead.nextFollowUpDate != null
                              ? DateFormatter.shortDate(lead.nextFollowUpDate!)
                              : 'Not scheduled',
                        ),
                      ]),
                    ],
                  ),

                  if (lead.followUpNote != null) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    SectionCard(
                      title: 'Follow-up Note',
                      child: Text(
                        lead.followUpNote!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  if (lead.activities != null &&
                      lead.activities!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    SectionCard(
                      title:
                          'Activity (${lead.activityCount ?? lead.activities!.length})',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lead.activities!
                            .map(
                              (a) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Text(
                                  '${labelForWireValue(leadActivityTypeLabels, a.type)}'
                                  '${a.createdByName != null ? ' — logged by ${a.createdByName}' : ''}: '
                                  '${a.note}',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete lead?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LeadDetailBloc>().add(LeadDetailDeleteRequested(id));
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConvertDialog(BuildContext context, int leadId) async {
    String selectedTier = leadTierLabels.keys.first;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Convert to Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select an Account Tier:'),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedTier,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: leadTierLabels.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedTier = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Convert'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result == true) {
        if (!context.mounted) return;
        context.read<LeadDetailBloc>().add(
          LeadDetailConvertRequested(leadId, tier: selectedTier),
        );
      }
    });
  }

  Widget _infoCard(String title, List<Widget> children) {
    return SizedBox(
      width: 340,
      child: SectionCard(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

extension on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width < 600;
}
