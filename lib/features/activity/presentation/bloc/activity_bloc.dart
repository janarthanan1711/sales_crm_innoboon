import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/activity.dart';
import '../../domain/usecases/activity_usecases.dart';
import 'activity_event.dart';
import 'activity_state.dart';
export 'activity_event.dart';
export 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final GetActivitiesUseCase getActivitiesUseCase;
  final LogActivityUseCase logActivityUseCase;
  
  String? _currentEntityType;
  String? _currentEntityId;
  ActivityType? _currentFilter;
  List<AppActivity> _allActivities = [];

  ActivityBloc({
    required this.getActivitiesUseCase,
    required this.logActivityUseCase,
  }) : super(const ActivityInitial()) {
    on<ActivityLoadRequested>((event, emit) async {
      _currentEntityType = event.entityType;
      _currentEntityId = event.entityId;
      emit(const ActivityLoading());
      await _load(emit);
    });
    
    on<ActivityFilterChanged>((event, emit) {
      _currentFilter = event.type;
      _emitFiltered(emit);
    });

    on<ActivityLogged>((event, emit) async {
      final result = await logActivityUseCase(event.activity);
      result.fold(
        (f) => emit(ActivityError(f.message)), 
        (a) async {
          if (_currentEntityType != null && _currentEntityId != null) {
            await _load(emit);
          }
        }
      );
    });
  }

  Future<void> _load(Emitter<ActivityState> emit) async {
    final result = await getActivitiesUseCase(GetActivitiesParams(
      entityType: _currentEntityType!,
      entityId: _currentEntityId!,
    ));
    result.fold(
      (f) => emit(ActivityError(f.message)),
      (activities) {
        _allActivities = activities;
        _emitFiltered(emit);
      }
    );
  }

  void _emitFiltered(Emitter<ActivityState> emit) {
    if (_currentFilter == null) {
      emit(ActivityLoaded(_allActivities, filterType: null));
    } else {
      final filtered = _allActivities.where((a) => a.type == _currentFilter).toList();
      emit(ActivityLoaded(filtered, filterType: _currentFilter));
    }
  }
}
