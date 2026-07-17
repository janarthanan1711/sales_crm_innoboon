import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_sales_metrics_usecase.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';
export 'analytics_event.dart';
export 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetSalesMetricsUseCase getSalesMetricsUseCase;

  AnalyticsBloc({required this.getSalesMetricsUseCase}) : super(const AnalyticsInitial()) {
    on<AnalyticsLoadRequested>((event, emit) async {
      emit(const AnalyticsLoading());
      final result = await getSalesMetricsUseCase(GetSalesMetricsParams(period: event.period));
      result.fold(
        (f) => emit(AnalyticsError(f.message)), 
        (m) => emit(AnalyticsLoaded(m))
      );
    });
  }
}
