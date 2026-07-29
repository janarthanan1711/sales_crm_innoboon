import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
export 'dashboard_event.dart';
export 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase getDashboardUseCase;

  String _period = 'this_month';

  DashboardBloc({required this.getDashboardUseCase})
    : super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  /// Trend granularity paired with each period so the conversion-trend buckets
  /// make sense for the window being shown.
  String get _granularity {
    switch (_period) {
      case 'today':
        return 'daily';
      case 'this_week':
        return 'daily';
      default:
        return 'monthly';
    }
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.period != null) _period = event.period!;
    emit(DashboardLoading(_period));
    final result = await getDashboardUseCase(
      GetDashboardParams(period: _period, granularity: _granularity),
    );
    result.fold(
      (f) => emit(DashboardError(f.message, _period)),
      (data) => emit(DashboardLoaded(data, _period)),
    );
  }
}
