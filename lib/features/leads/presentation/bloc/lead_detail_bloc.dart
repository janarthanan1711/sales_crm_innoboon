import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/convert_lead_usecase.dart';
import '../../domain/usecases/delete_lead_usecase.dart';
import '../../domain/usecases/list_lead_activities_usecase.dart';
import '../../domain/usecases/log_lead_activity_usecase.dart';
import '../../domain/usecases/update_lead_activity_usecase.dart';
import '../../domain/usecases/delete_lead_activity_usecase.dart';
import '../../domain/usecases/set_lead_favourite_usecase.dart';
import 'lead_detail_event.dart';
import 'lead_detail_state.dart';
export 'lead_detail_event.dart';
export 'lead_detail_state.dart';

class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  final GetLeadByIdUseCase getLeadByIdUseCase;
  final ConvertLeadToAccountUseCase convertLeadUseCase;
  final DeleteLeadUseCase deleteLeadUseCase;
  final ListLeadActivitiesUseCase listLeadActivitiesUseCase;
  final LogLeadActivityUseCase logLeadActivityUseCase;
  final UpdateLeadActivityUseCase updateLeadActivityUseCase;
  final DeleteLeadActivityUseCase deleteLeadActivityUseCase;
  final SetLeadFavouriteUseCase setLeadFavouriteUseCase;

  LeadDetailBloc({
    required this.getLeadByIdUseCase,
    required this.convertLeadUseCase,
    required this.deleteLeadUseCase,
    required this.listLeadActivitiesUseCase,
    required this.logLeadActivityUseCase,
    required this.updateLeadActivityUseCase,
    required this.deleteLeadActivityUseCase,
    required this.setLeadFavouriteUseCase,
  }) : super(const LeadDetailInitial()) {
    on<LeadDetailLoadRequested>(_onLoadRequested);
    on<LeadDetailConvertRequested>(_onConvertRequested);
    on<LeadDetailDeleteRequested>(_onDeleteRequested);
    on<LeadDetailActivityFilterChanged>(_onActivityFilterChanged);
    on<LeadDetailActivityLogRequested>(_onActivityLogRequested);
    on<LeadDetailActivityUpdateRequested>(_onActivityUpdateRequested);
    on<LeadDetailActivityDeleteRequested>(_onActivityDeleteRequested);
    on<LeadDetailFavouriteToggled>(_onFavouriteToggled);
  }

  Future<void> _onLoadRequested(
    LeadDetailLoadRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(const LeadDetailLoading());
    final result = await getLeadByIdUseCase(event.leadId);
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (lead) => emit(
        LeadDetailLoaded(
          lead,
          activities: lead.activities ?? [],
          // All types ticked to start, matching the Accounts detail page.
          activityTypeFilter: leadActivityTypeLabels.keys.toSet(),
        ),
      ),
    );
  }

  Future<void> _onActivityFilterChanged(
    LeadDetailActivityFilterChanged event,
    Emitter<LeadDetailState> emit,
  ) async {
    final current = state;
    if (current is! LeadDetailLoaded) return;
    final result = await listLeadActivitiesUseCase(
      ListLeadActivitiesParams(
        leadId: event.leadId,
        types: _typesParam(event.types),
        dateFrom: event.dateFrom,
        dateTo: event.dateTo,
      ),
    );
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (activities) => emit(
        current.copyWith(
          activities: activities,
          activityTypeFilter: event.types,
          activityDateFrom: event.dateFrom,
          clearActivityDateFrom: event.dateFrom == null,
          activityDateTo: event.dateTo,
          clearActivityDateTo: event.dateTo == null,
        ),
      ),
    );
  }

  Future<void> _onActivityLogRequested(
    LeadDetailActivityLogRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    final current = state;
    if (current is! LeadDetailLoaded) return;
    final result = await logLeadActivityUseCase(
      LogLeadActivityParams(
        leadId: event.leadId,
        type: event.type,
        note: event.note,
      ),
    );
    await result.fold(
      (failure) async => emit(LeadDetailError(failure.message)),
      (_) async => _refreshAfterMutation(event.leadId, current, emit),
    );
  }

  Future<void> _onActivityUpdateRequested(
    LeadDetailActivityUpdateRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    final current = state;
    if (current is! LeadDetailLoaded) return;
    final result = await updateLeadActivityUseCase(
      UpdateLeadActivityParams(
        leadId: event.leadId,
        activityId: event.activityId,
        type: event.type,
        note: event.note,
      ),
    );
    await result.fold(
      (failure) async => emit(LeadDetailError(failure.message)),
      (_) async => _refreshAfterMutation(event.leadId, current, emit),
    );
  }

  Future<void> _onActivityDeleteRequested(
    LeadDetailActivityDeleteRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    final current = state;
    if (current is! LeadDetailLoaded) return;
    final result = await deleteLeadActivityUseCase(
      DeleteLeadActivityParams(
        leadId: event.leadId,
        activityId: event.activityId,
      ),
    );
    await result.fold(
      (failure) async => emit(LeadDetailError(failure.message)),
      (_) async => _refreshAfterMutation(event.leadId, current, emit),
    );
  }

  /// After any activity mutation: refresh the lead itself (so overview stats
  /// like `activityCount`/`lastContact` stay in sync) and re-apply whatever
  /// activity filter is currently active.
  Future<void> _refreshAfterMutation(
    int leadId,
    LeadDetailLoaded current,
    Emitter<LeadDetailState> emit,
  ) async {
    final leadResult = await getLeadByIdUseCase(leadId);
    final activitiesResult = await listLeadActivitiesUseCase(
      ListLeadActivitiesParams(
        leadId: leadId,
        types: _typesParam(current.activityTypeFilter),
        dateFrom: current.activityDateFrom,
        dateTo: current.activityDateTo,
      ),
    );
    leadResult.fold((failure) => emit(LeadDetailError(failure.message)), (
      lead,
    ) {
      activitiesResult.fold(
        (failure) => emit(current.copyWith(lead: lead)),
        (activities) =>
            emit(current.copyWith(lead: lead, activities: activities)),
      );
    });
  }

  /// The `types` query parameter for a set of selected activity types.
  ///
  /// Null — meaning "don't filter by type" — for both extremes: nothing
  /// ticked and everything ticked. Spelling out all five would ask the backend
  /// for a narrower thing than the user selected, and it breaks the moment a
  /// new activity type is added server-side.
  List<String>? _typesParam(Set<String> types) {
    if (types.isEmpty) return null;
    if (types.length == leadActivityTypeLabels.length) return null;
    return types.toList();
  }

  Future<void> _onConvertRequested(
    LeadDetailConvertRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(const LeadDetailLoading());
    final result = await convertLeadUseCase(
      ConvertLeadParams(
        leadId: event.leadId,
        tier: event.tier,
        ownerId: event.ownerId,
      ),
    );
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (accountId) => emit(LeadDetailConverted(accountId)),
    );
  }

  Future<void> _onFavouriteToggled(
    LeadDetailFavouriteToggled event,
    Emitter<LeadDetailState> emit,
  ) async {
    final current = state;
    if (current is! LeadDetailLoaded) return;
    final result = await setLeadFavouriteUseCase(
      SetLeadFavouriteParams(id: event.leadId, isFavourite: event.isFavourite),
    );
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (lead) => emit(current.copyWith(lead: lead)),
    );
  }

  Future<void> _onDeleteRequested(
    LeadDetailDeleteRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(const LeadDetailLoading());
    final result = await deleteLeadUseCase(event.leadId);
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (_) => emit(const LeadDetailDeleted()),
    );
  }
}
