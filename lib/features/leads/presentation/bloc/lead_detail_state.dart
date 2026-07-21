import 'package:equatable/equatable.dart';
import '../../domain/entities/lead.dart';

abstract class LeadDetailState extends Equatable {
  const LeadDetailState();
  @override
  List<Object?> get props => [];
}

class LeadDetailInitial extends LeadDetailState {
  const LeadDetailInitial();
}

class LeadDetailLoading extends LeadDetailState {
  const LeadDetailLoading();
}

class LeadDetailLoaded extends LeadDetailState {
  final Lead lead;
  /// Activities currently shown on the Activity tab — starts as
  /// `lead.activities` and is replaced whenever a filter changes or a
  /// mutation (log/update/delete) completes.
  final List<LeadActivity> activities;
  final Set<String> activityTypeFilter;
  final DateTime? activityDateFrom;
  final DateTime? activityDateTo;

  const LeadDetailLoaded(
    this.lead, {
    this.activities = const [],
    this.activityTypeFilter = const {},
    this.activityDateFrom,
    this.activityDateTo,
  });

  LeadDetailLoaded copyWith({
    Lead? lead,
    List<LeadActivity>? activities,
    Set<String>? activityTypeFilter,
    DateTime? activityDateFrom,
    bool clearActivityDateFrom = false,
    DateTime? activityDateTo,
    bool clearActivityDateTo = false,
  }) {
    return LeadDetailLoaded(
      lead ?? this.lead,
      activities: activities ?? this.activities,
      activityTypeFilter: activityTypeFilter ?? this.activityTypeFilter,
      activityDateFrom: clearActivityDateFrom
          ? null
          : (activityDateFrom ?? this.activityDateFrom),
      activityDateTo: clearActivityDateTo
          ? null
          : (activityDateTo ?? this.activityDateTo),
    );
  }

  @override
  List<Object?> get props => [
    lead,
    activities,
    activityTypeFilter,
    activityDateFrom,
    activityDateTo,
  ];
}

class LeadDetailError extends LeadDetailState {
  final String message;
  const LeadDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class LeadDetailConverted extends LeadDetailState {
  final int accountId;
  const LeadDetailConverted(this.accountId);
  @override
  List<Object?> get props => [accountId];
}

class LeadDetailDeleted extends LeadDetailState {
  const LeadDetailDeleted();
}
