import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notification_event.dart';
import 'notification_state.dart';
export 'notification_event.dart';
export 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkNotificationUnreadUseCase markNotificationUnreadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;
  final MarkManyNotificationsReadUseCase markManyNotificationsReadUseCase;
  final DeleteNotificationsUseCase deleteNotificationsUseCase;

  static const _pageSize = 20;

  NotificationBloc({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markNotificationUnreadUseCase,
    required this.markAllNotificationsReadUseCase,
    required this.markManyNotificationsReadUseCase,
    required this.deleteNotificationsUseCase,
  }) : super(const NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationLoadMoreRequested>(_onLoadMoreRequested);
    on<NotificationMarkedRead>(_onMarkedRead);
    on<NotificationMarkedUnread>(_onMarkedUnread);
    on<NotificationMarkedAllRead>(_onMarkedAllRead);
    on<NotificationsBulkMarkReadRequested>(_onBulkMarkedRead);
    on<NotificationsBulkDeleteRequested>(_onBulkDeleted);
  }

  Future<void> _onLoadRequested(NotificationLoadRequested event, Emitter<NotificationState> emit) async {
    emit(const NotificationLoading());
    await _load(emit, unreadOnly: event.unreadOnly, typeFilter: event.typeFilter, offset: 0);
  }

  Future<void> _onLoadMoreRequested(NotificationLoadMoreRequested event, Emitter<NotificationState> emit) async {
    final current = state;
    if (current is! NotificationLoaded || current.isLoadingMore || !current.hasMore) return;
    emit(current.copyWith(isLoadingMore: true));

    final result = await getNotificationsUseCase(GetNotificationsParams(
      unreadOnly: current.unreadOnly,
      type: current.typeFilter,
      limit: _pageSize,
      offset: current.notifications.length,
    ));

    result.fold(
      (f) => emit(current.copyWith(isLoadingMore: false)),
      (page) => emit(current.copyWith(
        notifications: [...current.notifications, ...page.items],
        total: page.total,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onMarkedRead(NotificationMarkedRead event, Emitter<NotificationState> emit) async {
    await markNotificationReadUseCase(event.id);
    await _reload(emit);
  }

  Future<void> _onMarkedUnread(NotificationMarkedUnread event, Emitter<NotificationState> emit) async {
    await markNotificationUnreadUseCase(event.id);
    await _reload(emit);
  }

  Future<void> _onMarkedAllRead(NotificationMarkedAllRead event, Emitter<NotificationState> emit) async {
    await markAllNotificationsReadUseCase(const NoParams());
    await _reload(emit);
  }

  Future<void> _onBulkMarkedRead(NotificationsBulkMarkReadRequested event, Emitter<NotificationState> emit) async {
    await markManyNotificationsReadUseCase(event.ids);
    await _reload(emit);
  }

  Future<void> _onBulkDeleted(NotificationsBulkDeleteRequested event, Emitter<NotificationState> emit) async {
    await deleteNotificationsUseCase(event.ids);
    await _reload(emit);
  }

  Future<void> _reload(Emitter<NotificationState> emit) async {
    final current = state;
    final unreadOnly = current is NotificationLoaded ? current.unreadOnly : false;
    final typeFilter = current is NotificationLoaded ? current.typeFilter : null;
    await _load(emit, unreadOnly: unreadOnly, typeFilter: typeFilter, offset: 0);
  }

  Future<void> _load(
    Emitter<NotificationState> emit, {
    required bool unreadOnly,
    NotificationType? typeFilter,
    required int offset,
  }) async {
    final notificationsResult = await getNotificationsUseCase(GetNotificationsParams(
      unreadOnly: unreadOnly,
      type: typeFilter,
      limit: _pageSize,
      offset: offset,
    ));
    final countResult = await getUnreadCountUseCase(const NoParams());

    notificationsResult.fold(
      (f) => emit(NotificationError(f.message)),
      (page) {
        countResult.fold(
          (f) => emit(NotificationError(f.message)),
          (count) => emit(NotificationLoaded(
            notifications: page.items,
            total: page.total,
            limit: _pageSize,
            unreadCount: count,
            unreadOnly: unreadOnly,
            typeFilter: typeFilter,
          )),
        );
      },
    );
  }
}
