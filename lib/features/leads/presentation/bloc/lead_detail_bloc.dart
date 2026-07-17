import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_lead_by_id_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/convert_lead_usecase.dart';
import 'lead_detail_event.dart';
import 'lead_detail_state.dart';
export 'lead_detail_event.dart';
export 'lead_detail_state.dart';

class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  final GetLeadByIdUseCase getLeadByIdUseCase;
  final UpdateLeadUseCase updateLeadUseCase;
  final ConvertLeadToAccountUseCase convertLeadUseCase;

  LeadDetailBloc({
    required this.getLeadByIdUseCase,
    required this.updateLeadUseCase,
    required this.convertLeadUseCase,
  }) : super(const LeadDetailInitial()) {
    on<LeadDetailLoadRequested>(_onLoadRequested);
    on<LeadDetailUpdateRequested>(_onUpdateRequested);
    on<LeadDetailConvertRequested>(_onConvertRequested);
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

  Future<void> _onUpdateRequested(
    LeadDetailUpdateRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(const LeadDetailLoading());
    final result = await updateLeadUseCase(event.lead);
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
    final result = await convertLeadUseCase(event.leadId);
    result.fold(
      (failure) => emit(LeadDetailError(failure.message)),
      (accountId) => emit(LeadDetailConverted(accountId)),
    );
  }
}
