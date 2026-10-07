import 'package:flutter/material.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/entities/source_person.dart';
import '../../domain/usecases/account_source_usecases.dart';
import 'person_type_icon.dart';

/// "Source Detail" tab: the ordered chain of people (platform Users and/or
/// Contacts) through whom this account reached us, e.g. Ram → TT Bhat →
/// Radhika. Read-only timeline by default; Edit adds drag-to-reorder, remove
/// and "Add person" (searchable), saved or discarded as a whole.
class SourceDetailTab extends StatefulWidget {
  final String accountId;
  const SourceDetailTab({super.key, required this.accountId});

  @override
  State<SourceDetailTab> createState() => _SourceDetailTabState();
}

class _SourceDetailTabState extends State<SourceDetailTab> {
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;
  List<SourcePerson> _people = [];
  List<SourcePerson> _saved = [];
  List<SourcePerson> _draft = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      sl<GetSourcePeopleUseCase>()(),
      sl<GetSourceDetailUseCase>()(widget.accountId),
    ]);
    if (!mounted) return;
    final people = results[0].fold((f) => null, (v) => v);
    final saved = results[1].fold((f) => null, (v) => v);
    setState(() {
      _loading = false;
      if (people == null || saved == null) {
        _error = 'Could not load source details.';
        return;
      }
      _people = people;
      _saved = saved;
    });
  }

  void _startEditing() => setState(() {
    _draft = [..._saved];
    _editing = true;
  });

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final result = await sl<SaveSourceDetailUseCase>()(
      widget.accountId,
      _draft,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      result.fold((_) {}, (saved) {
        _saved = saved;
        _editing = false;
      });
    });
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => messenger.showSnackBar(
        const SnackBar(content: Text('Source detail saved')),
      ),
    );
  }

  Future<void> _addPerson() async {
    final picked = await showDialog<SourcePerson>(
      context: context,
      builder: (_) => _PersonPickerDialog(
        people: _people,
        taken: {for (final p in _draft) p.key},
      ),
    );
    if (picked != null) setState(() => _draft = [..._draft, picked]);
  }

  /// A user and a contact sharing an email are probably the same person.
  String? _sameEmailWarning() {
    final seen = <String, SourcePerson>{};
    for (final p in _draft) {
      final email = p.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) continue;
      final other = seen[email];
      if (other != null && other.type != p.type) {
        return '${other.name} and ${p.name} share the email $email — '
            'are they the same person?';
      }
      seen[email] = p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: AppTextStyles.bodyMedium));
    }
    final chain = _editing ? _draft : _saved;
    final warning = _editing ? _sameEmailWarning() : null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionCard(
          title: 'Source Detail',
          trailing: _editing
              ? null
              : OutlinedButton.icon(
                  onPressed: _startEditing,
                  icon: Icon(_saved.isEmpty ? Icons.add : Icons.edit, size: 16),
                  label: Text(_saved.isEmpty ? 'Add source' : 'Edit'),
                ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who this account moved through to reach us, in order.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (chain.isEmpty)
                  Text(
                    _editing
                        ? 'Nobody added yet — use "Add person".'
                        : 'No source chain recorded yet.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                else if (_editing)
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    onReorder: (from, to) => setState(() {
                      final item = _draft.removeAt(from);
                      _draft.insert(to, item);
                    }),
                    children: [
                      for (var i = 0; i < _draft.length; i++)
                        _StepRow(
                          key: ValueKey(_draft[i].key),
                          person: _draft[i],
                          index: i,
                          count: _draft.length,
                          editing: true,
                          onRemove: () => setState(() => _draft.removeAt(i)),
                        ),
                    ],
                  )
                else
                  for (var i = 0; i < chain.length; i++)
                    _StepRow(
                      person: chain[i],
                      index: i,
                      count: chain.length,
                      editing: false,
                    ),
                if (warning != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    warning,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
                if (_editing) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _addPerson,
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('Add person'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _editing = false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One person on the timeline: a rail (dot + connecting line) and a card.
class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.person,
    required this.index,
    required this.count,
    required this.editing,
    this.onRemove,
  });
  final SourcePerson person;
  final int index;
  final int count;
  final bool editing;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final isFirst = index == 0;
    final isLast = index == count - 1;
    final tag = count == 1
        ? null
        : isFirst
        ? 'ORIGIN'
        : isLast
        ? 'REACHED US'
        : null;
    final details = [
      if (person.email != null && person.email!.isNotEmpty) person.email!,
      if (person.phone != null && person.phone!.isNotEmpty) person.phone!,
    ].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  children: [
                    PersonTypeIcon(person.type),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(person.name, style: AppTextStyles.labelLarge),
                          if (details.isNotEmpty)
                            Text(
                              details,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (tag != null)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Text(
                          tag,
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    if (editing) ...[
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: onRemove,
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator, size: 20),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable list of everyone selectable; people already in the chain are
/// shown greyed out rather than hidden.
class _PersonPickerDialog extends StatefulWidget {
  const _PersonPickerDialog({required this.people, required this.taken});
  final List<SourcePerson> people;
  final Set<String> taken;

  @override
  State<_PersonPickerDialog> createState() => _PersonPickerDialogState();
}

class _PersonPickerDialogState extends State<_PersonPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final matches = widget.people
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              (p.email ?? '').toLowerCase().contains(q),
        )
        .toList();
    return AlertDialog(
      title: const Text('Add person'),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Search by name or email',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text(
                        'No matches',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (_, i) {
                        final p = matches[i];
                        final taken = widget.taken.contains(p.key);
                        final details = [
                          if (p.email != null && p.email!.isNotEmpty) p.email!,
                          if (p.phone != null && p.phone!.isNotEmpty) p.phone!,
                        ].join(' · ');
                        return ListTile(
                          enabled: !taken,
                          dense: true,
                          leading: PersonTypeIcon(p.type),
                          title: Text(p.name),
                          subtitle: Text(
                            taken ? 'Already in chain' : details,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
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
      ],
    );
  }
}
