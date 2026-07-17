import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_deal_by_id_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import 'deal_detail_event.dart';
import 'deal_detail_state.dart';
export 'deal_detail_event.dart';
export 'deal_detail_state.dart';

class DealDetailBloc extends Bloc<DealDetailEvent, DealDetailState> {
  final GetDealByIdUseCase getDealByIdUseCase;
  final UpdateDealStageUseCase updateDealStageUseCase;
  
  DealDetailBloc({required this.getDealByIdUseCase, required this.updateDealStageUseCase}) : super(const DealDetailInitial()) {
    on<DealDetailLoadRequested>((event, emit) async {
      emit(const DealDetailLoading());
      final result = await getDealByIdUseCase(event.id);
      result.fold((f) => emit(DealDetailError(f.message)), (d) => emit(DealDetailLoaded(d)));
    });
    
    on<DealDetailStageUpdateRequested>((event, emit) async {
      emit(const DealDetailLoading());
      final result = await updateDealStageUseCase(UpdateDealStageParams(id: event.id, stage: event.stage));
      result.fold((f) => emit(DealDetailError(f.message)), (d) => emit(DealDetailLoaded(d)));
    });
  }
}
