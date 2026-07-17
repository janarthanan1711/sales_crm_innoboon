import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_event.dart';
import 'notification_state.dart';
export 'notification_event.dart';
export 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllNotificationsReadUseCase,
  }) : super(const NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationMarkedAllRead>(_onMarkedAllRead);
  }

  Future<void> _onLoadRequested(NotificationLoadRequested event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    await _load(emit);
  }

  Future<void> _onMarkedRead(NotificationMarkedRead event, Emitter<NotificationState> emit) async {
    await markNotificationReadUseCase(event.id);
    await _load(emit);
  }

  Future<void> _onMarkedAllRead(NotificationMarkedAllRead event, Emitter<NotificationState> emit) async {
    await markAllNotificationsReadUseCase(NoParams());
    await _load(emit);
  }

  Future<void> _load(Emitter<NotificationState> emit) async {
    final notificationsResult = await getNotificationsUseCase(NoParams());
    final countResult = await getUnreadCountUseCase(NoParams());
    
    notificationsResult.fold(
      (f) => emit(NotificationError(f.message)),
      (notifications) {
        countResult.fold(
          (f) => emit(NotificationError(f.message)),
          (count) => emit(NotificationLoaded(notifications: notifications, unreadCount: count)),
        );
      }
    );
  }
}
