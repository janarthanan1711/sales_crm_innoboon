import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/convert_lead_usecase.dart';
import '../../domain/usecases/delete_lead_usecase.dart';
import 'lead_detail_event.dart';
import 'lead_detail_state.dart';
export 'lead_detail_event.dart';
export 'lead_detail_state.dart';

class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  final GetLeadByIdUseCase getLeadByIdUseCase;
  final ConvertLeadToAccountUseCase convertLeadUseCase;
  final DeleteLeadUseCase deleteLeadUseCase;

  LeadDetailBloc({
    required this.getLeadByIdUseCase,
    required this.convertLeadUseCase,
    required this.deleteLeadUseCase,
  }) : super(const LeadDetailInitial()) {
    on<LeadDetailLoadRequested>(_onLoadRequested);
    on<LeadDetailConvertRequested>(_onConvertRequested);
    on<LeadDetailDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    LeadDetailLoadRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(const LeadDetailLoading());
    final result = await getLeadByIdUseCase(event.leadId);
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (lead) => emit(LeadDetailLoaded(lead)),
    );
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
