import 'package:flutter/material.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../leads/domain/entities/lead_enums.dart';
import '../../domain/entities/account_options.dart';
import '../../domain/usecases/account_source_usecases.dart';

enum AccountField { source, country, engagementType }

/// Source / Country / Engagement Type dropdowns, shared by the New Account
/// page and the Edit Account dialog. Source reuses the lead-source values;
/// country and engagement-type options come from `GET /accounts/options`.
class AccountClassificationFields extends StatefulWidget {
  final String? source;
  final String? country;
  final String? engagementType;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onEngagementTypeChanged;

  /// Which dropdowns to render (the New Account page splits them around City).
  final Set<AccountField> show;

  /// Label above the field (matches the New Account form) instead of a
  /// floating label (Edit Account dialog).
  final bool labelAbove;

  const AccountClassificationFields({
    super.key,
    this.show = const {
      AccountField.source,
      AccountField.country,
      AccountField.engagementType,
    },
    this.labelAbove = false,
    this.source,
    this.country,
    this.engagementType,
    required this.onSourceChanged,
    required this.onCountryChanged,
    required this.onEngagementTypeChanged,
  });

  @override
  State<AccountClassificationFields> createState() =>
      _AccountClassificationFieldsState();
}

class _AccountClassificationFieldsState
    extends State<AccountClassificationFields> {
  AccountOptions? _options;
  late String? _source = widget.source;
  late String? _country = widget.country;
  late String? _engagementType = widget.engagementType;

  @override
  void initState() {
    super.initState();
    sl<GetAccountOptionsUseCase>()().then((result) {
      if (!mounted) return;
      result.fold((_) {}, (o) => setState(() => _options = o));
    });
  }

  List<DropdownMenuItem<String?>> _items(Map<String, String> labels) => [
    const DropdownMenuItem<String?>(value: null, child: Text('Not set')),
    for (final e in labels.entries)
      DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
  ];

  @override
  Widget build(BuildContext context) {
    final options = _options;
    // A saved value must be present in the items or the dropdown asserts.
    final countries = options?.countries ?? const <String>[];
    final countryValue = countries.contains(_country) ? _country : null;
    final engagementLabels = options?.engagementTypes ?? const {};
    final engagementValue = engagementLabels.containsKey(_engagementType)
        ? _engagementType
        : null;
    InputDecoration deco(String label) => widget.labelAbove
        ? InputDecoration(hintText: 'Select ${label.toLowerCase()}')
        : InputDecoration(labelText: label);
    Widget field(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelAbove)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(label, style: AppTextStyles.labelMedium),
          ),
        child,
      ],
    );

    final fields = <Widget>[
      if (widget.show.contains(AccountField.source))
        field(
          'Source',
          DropdownButtonFormField<String?>(
            initialValue: leadSourceLabels.containsKey(_source)
                ? _source
                : null,
            isExpanded: true,
            decoration: deco('Source'),
            items: _items(leadSourceLabels),
            onChanged: (v) {
              setState(() => _source = v);
              widget.onSourceChanged(v);
            },
          ),
        ),
      if (widget.show.contains(AccountField.country))
        field(
          'Country / Region',
          // Type-to-filter, since the list is ~190 long.
          DropdownMenu<String?>(
            key: ValueKey('country-${options != null}'),
            initialSelection: countryValue,
            expandedInsets: EdgeInsets.zero,
            label: widget.labelAbove ? null : const Text('Country / Region'),
            hintText: widget.labelAbove ? 'Select country' : null,
            enableFilter: true,
            requestFocusOnTap: true,
            menuHeight: 300,
            dropdownMenuEntries: [
              const DropdownMenuEntry<String?>(value: null, label: 'Not set'),
              for (final c in countries)
                DropdownMenuEntry<String?>(value: c, label: c),
            ],
            onSelected: (v) {
              setState(() => _country = v);
              widget.onCountryChanged(v);
            },
          ),
        ),
      if (widget.show.contains(AccountField.engagementType))
        field(
          'Engagement Type',
          DropdownButtonFormField<String?>(
            key: ValueKey('engagement-${options != null}'),
            initialValue: engagementValue,
            isExpanded: true,
            decoration: deco('Engagement Type'),
            items: _items(engagementLabels),
            onChanged: (v) {
              setState(() => _engagementType = v);
              widget.onEngagementTypeChanged(v);
            },
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          fields[i],
        ],
      ],
    );
  }
}
