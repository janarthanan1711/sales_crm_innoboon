import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/link_launcher.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/document.dart';
import '../bloc/documents_list_bloc.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<DocumentsListBloc>()..add(const DocumentsListLoadRequested()),
      child: const _DocumentsView(),
    );
  }
}

/// (label, wire value) for the source filter. Empty value = both.
const List<(String, String)> _kSources = [
  ('All', ''),
  ('Accounts', 'account'),
  ('Deals', 'deal'),
];

class _DocumentsView extends StatefulWidget {
  const _DocumentsView();

  @override
  State<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<_DocumentsView> {
  final _searchController = TextEditingController();
  String _search = '';
  String _source = ''; // '' | 'account' | 'deal'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Client-side source + case-insensitive file-name filter over the already
  /// visibility-scoped list.
  List<Document> _apply(List<Document> all) {
    final q = _search.trim().toLowerCase();
    return all.where((d) {
      if (_source.isNotEmpty && d.source != _source) return false;
      if (q.isNotEmpty && !d.fileName.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
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
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            _buildFilters(context),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: BlocBuilder<DocumentsListBloc, DocumentsListState>(
                builder: (context, state) {
                  if (state is DocumentsListLoading ||
                      state is DocumentsListInitial) {
                    return const AppLoadingIndicator(
                      message: 'Loading documents...',
                    );
                  }
                  if (state is DocumentsListError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<DocumentsListBloc>().add(
                        const DocumentsListLoadRequested(),
                      ),
                    );
                  }
                  if (state is DocumentsListLoaded) {
                    final docs = _apply(state.documents);
                    if (docs.isEmpty) {
                      return EmptyState(
                        icon: Icons.description_outlined,
                        title: state.documents.isEmpty
                            ? 'No documents yet'
                            : 'No matching documents',
                        subtitle: state.documents.isEmpty
                            ? 'Documents uploaded to accounts and deals appear here.'
                            : 'Try a different search or filter.',
                      );
                    }
                    return _DocumentsTable(documents: docs);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(
          'Every file across your accounts and deals, newest first.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: context.isMobile ? 220 : 300,
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Search by file name...',
              onChanged: (q) => setState(() => _search = q),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _SourceToggle(
            selected: _source,
            onSelected: (s) => setState(() => _source = s),
          ),
        ],
      ),
    );
  }
}

// ─── Source segmented toggle ────────────────────────────
class _SourceToggle extends StatelessWidget {
  const _SourceToggle({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _kSources.map((s) {
          final active = s.$2 == selected;
          return GestureDetector(
            onTap: () => onSelected(s.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius - 2),
              ),
              child: Text(
                s.$1,
                style: AppTextStyles.labelMedium.copyWith(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Table ──────────────────────────────────────────────
class _DocumentsTable extends StatelessWidget {
  const _DocumentsTable({required this.documents});
  final List<Document> documents;

  @override
  Widget build(BuildContext context) {
    final table = Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _h('DOCUMENT', flex: 4),
                _h('SOURCE', flex: 2),
                _h('LINKED TO', flex: 3),
                _h('TYPE', flex: 2),
                _h('UPLOADED', flex: 2),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: documents.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _DocumentRow(document: documents[i]),
            ),
          ),
        ],
      ),
    );

    // The 5-column table needs room; on phones let it scroll horizontally.
    if (context.isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 900, child: table),
      );
    }
    return table;
  }

  Widget _h(String label, {int flex = 1}) =>
      Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));
}

class _DocumentRow extends StatefulWidget {
  const _DocumentRow({required this.document});
  final Document document;

  @override
  State<_DocumentRow> createState() => _DocumentRowState();
}

class _DocumentRowState extends State<_DocumentRow> {
  bool _hovered = false;

  IconData _icon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  void _open() {
    final url = resolveMediaUrl(widget.document.fileUrl);
    if (url != null) launchWebUrl(url);
  }

  void _goToEntity() {
    final d = widget.document;
    context.go(d.isAccount ? '/accounts/${d.entityId}' : '/deals/${d.entityId}');
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          color: _hovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Icon(_icon(d.extension), size: 22, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        d.fileName,
                        style: AppTextStyles.tableCellLink,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: _SourceBadge(isAccount: d.isAccount)),
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: _goToEntity,
                  child: Text(
                    d.entityName.isEmpty ? '—' : d.entityName,
                    style: AppTextStyles.tableCell.copyWith(
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  d.extension.isNotEmpty
                      ? d.extension.toUpperCase()
                      : d.contentType,
                  style: AppTextStyles.tableCell,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  DateFormatter.displayDate(d.createdAt),
                  style: AppTextStyles.tableCell,
                ),
              ),
              SizedBox(
                width: 48,
                child: IconButton(
                  tooltip: 'Open',
                  icon: const Icon(Icons.open_in_new, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: _open,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Account / Deal pill, colour-coded to match the tier/status badge language.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isAccount});
  final bool isAccount;

  @override
  Widget build(BuildContext context) {
    final color = isAccount ? AppColors.primary : const Color(0xFF7C3AED);
    final label = isAccount ? 'Account' : 'Deal';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAccount ? Icons.business_outlined : Icons.handshake_outlined,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.badge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
