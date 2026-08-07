import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_range.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';
export 'dashboard_event.dart';
export 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardUseCase getDashboardUseCase;

  /// Only used to resolve leaderboard avatars — see [_withAvatars].
  final GetUsersUseCase getUsersUseCase;

  DashboardRange _range = const DashboardRange();

  /// ownerId → avatar path, fetched at most once per bloc instance. Empty (not
  /// null) once a fetch has been attempted and returned nothing usable, so a
  /// failing/forbidden `GET /users` isn't retried on every period switch.
  Map<int, String>? _avatarsByOwnerId;

  DashboardBloc({
    required this.getDashboardUseCase,
    required this.getUsersUseCase,
  }) : super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.range != null) _range = event.range!;
    emit(DashboardLoading(_range));
    final result = await getDashboardUseCase(GetDashboardParams(range: _range));
    await result.fold(
      (f) async => emit(DashboardError(_explain(f.message), _range)),
      (data) async => emit(DashboardLoaded(await _withAvatars(data), _range)),
    );
  }

  /// A `custom` range only works against a build whose `period` enum accepts
  /// it; without this the user just sees a raw validation error.
  String _explain(String message) {
    if (!_range.isCustom) return message;
    return '$message\n\n'
        'Custom date ranges need the dashboard API to accept '
        '`period=custom` with `start_date`/`end_date`.';
  }

  /// Fills in leaderboard avatars the payload didn't carry.
  ///
  /// `GET /dashboard` returns `owner_id`/`owner_name` but (in the builds seen
  /// so far) no avatar, so the rep's photo is looked up from `GET /users` by
  /// id. Entries that already carry an avatar are left alone, so this becomes
  /// a no-op the moment the API returns `owner_avatar_url` itself.
  Future<DashboardData> _withAvatars(DashboardData data) async {
    final missing = data.leaderboard.where((e) => e.avatarUrl == null);
    if (missing.isEmpty) return data;

    if (_avatarsByOwnerId == null) {
      final users = await getUsersUseCase();
      _avatarsByOwnerId = users.fold(
        // No `users.view` (or the call failed) — fall back to initials.
        (_) => const {},
        (list) => {
          for (final u in list)
            if (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
              u.id: u.avatarUrl!,
        },
      );
    }
    final avatars = _avatarsByOwnerId!;
    if (avatars.isEmpty) return data;

    return data.withLeaderboard(
      data.leaderboard
          .map(
            (e) => e.avatarUrl != null
                ? e
                : e.copyWith(avatarUrl: avatars[e.ownerId]),
          )
          .toList(growable: false),
    );
  }
}
