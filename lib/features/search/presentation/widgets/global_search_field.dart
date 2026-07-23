import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/search_result.dart';
import '../bloc/search_bloc.dart';

/// Top-nav global search: a text field that opens a dropdown of results
/// grouped by type (Leads / Accounts / Deals / Contacts), backed by
/// `GET /search?q=`. Debounced client-side.
class GlobalSearchField extends StatelessWidget {
  const GlobalSearchField({super.key, this.width = 360});
  final double width;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>(),
      child: _GlobalSearchFieldView(width: width),
    );
  }
}

class _GlobalSearchFieldView extends StatefulWidget {
  const _GlobalSearchFieldView({required this.width});
  final double width;

  @override
  State<_GlobalSearchFieldView> createState() => _GlobalSearchFieldViewState();
}

class _GlobalSearchFieldViewState extends State<_GlobalSearchFieldView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _link = LayerLink();
  final _overlayController = OverlayPortalController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _controller.text.trim().isNotEmpty) {
      _overlayController.show();
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _overlayController.hide();
      context.read<SearchBloc>().add(const SearchCleared());
      return;
    }
    _overlayController.show();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<SearchBloc>().add(SearchQuerySubmitted(value));
    });
  }

  void _openResult(SearchResult r) {
    _overlayController.hide();
    _focusNode.unfocus();
    switch (r.type) {
      case SearchResultType.lead:
        context.go('/leads/${r.id}');
        break;
      case SearchResultType.account:
        context.go('/accounts/${r.id}');
        break;
      case SearchResultType.deal:
        context.go('/deals/${r.id}');
        break;
      case SearchResultType.contact:
      case SearchResultType.unknown:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open the related account to view “${r.label}”.')),
        );
        break;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => _buildOverlay(),
        child: SizedBox(
          width: widget.width,
          height: 40,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search accounts, leads, deals...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _overlayController.hide();
                        context.read<SearchBloc>().add(const SearchCleared());
                        setState(() {});
                      },
                    ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            style: AppTextStyles.bodyMedium,
            onTap: () {
              if (_controller.text.trim().isNotEmpty) _overlayController.show();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      width: widget.width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                    );
                  }
                  if (state is SearchError) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(state.message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                    );
                  }
                  if (state is SearchLoaded) {
                    if (state.results.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text('No results for “${state.query}”', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _group(context, 'LEADS', state.ofType(SearchResultType.lead)),
                          _group(context, 'ACCOUNTS', state.ofType(SearchResultType.account)),
                          _group(context, 'DEALS', state.ofType(SearchResultType.deal)),
                          _group(context, 'CONTACTS', state.ofType(SearchResultType.contact)),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<SearchResult> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
          child: Row(
            children: [
              Icon(_groupIcon(title), size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(title, style: AppTextStyles.overline),
            ],
          ),
        ),
        ...items.map((r) => InkWell(
              onTap: () => _openResult(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Text(r.label, style: AppTextStyles.bodyMedium),
              ),
            )),
        const Divider(height: 1),
      ],
    );
  }

  IconData _groupIcon(String title) {
    switch (title) {
      case 'LEADS':
        return Icons.person_outline;
      case 'ACCOUNTS':
        return Icons.business_outlined;
      case 'DEALS':
        return Icons.handshake_outlined;
      case 'CONTACTS':
        return Icons.contacts_outlined;
      default:
        return Icons.search;
    }
  }
}
