import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/interceptors/auth_interceptor.dart';

import '../router/auth_notifier.dart';
// Auth feature
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Leads feature
import '../../features/leads/data/datasources/lead_remote_datasource_impl.dart';
import '../../features/leads/data/repositories/lead_repository_impl.dart';
import '../../features/leads/domain/repositories/lead_repository.dart';
import '../../features/leads/domain/usecases/get_leads_usecase.dart';
import '../../features/leads/domain/usecases/get_lead_by_id_usecase.dart';
import '../../features/leads/domain/usecases/create_lead_usecase.dart';
import '../../features/leads/domain/usecases/update_lead_usecase.dart';
import '../../features/leads/domain/usecases/convert_lead_usecase.dart';
import '../../features/leads/domain/usecases/delete_lead_usecase.dart';
import '../../features/leads/domain/usecases/log_lead_activity_usecase.dart';
import '../../features/leads/presentation/bloc/leads_list_bloc.dart';
import '../../features/leads/presentation/bloc/lead_detail_bloc.dart';

// Users feature
import '../../features/users/data/datasources/user_remote_datasource.dart';
import '../../features/users/data/repositories/user_repository_impl.dart';
import '../../features/users/domain/repositories/user_repository.dart';
import '../../features/users/domain/usecases/get_users_usecase.dart';

// Accounts feature
import '../../features/accounts/data/datasources/account_mock_datasource.dart';
import '../../features/accounts/data/repositories/account_repository_impl.dart';
import '../../features/accounts/domain/repositories/account_repository.dart';
import '../../features/accounts/domain/usecases/get_accounts_usecase.dart';
import '../../features/accounts/domain/usecases/get_account_by_id_usecase.dart';
import '../../features/accounts/presentation/bloc/accounts_list_bloc.dart';
import '../../features/accounts/presentation/bloc/account_detail_bloc.dart';

// Deals feature
import '../../features/deals/data/datasources/deal_mock_datasource.dart';
import '../../features/deals/data/repositories/deal_repository_impl.dart';
import '../../features/deals/domain/repositories/deal_repository.dart';
import '../../features/deals/domain/usecases/get_deals_usecase.dart';
import '../../features/deals/domain/usecases/get_deal_by_id_usecase.dart';
import '../../features/deals/domain/usecases/create_deal_usecase.dart';
import '../../features/deals/domain/usecases/update_deal_stage_usecase.dart';
import '../../features/deals/presentation/bloc/deals_list_bloc.dart';
import '../../features/deals/presentation/bloc/deal_detail_bloc.dart';

// Checklist feature
import '../../features/checklist/data/datasources/checklist_mock_datasource.dart';
import '../../features/checklist/data/repositories/checklist_repository_impl.dart';
import '../../features/checklist/domain/repositories/checklist_repository.dart';
import '../../features/checklist/domain/usecases/checklist_usecases.dart';
import '../../features/checklist/presentation/bloc/checklist_bloc.dart';

// Activity feature
import '../../features/activity/data/datasources/activity_mock_datasource.dart';
import '../../features/activity/data/repositories/activity_repository_impl.dart';
import '../../features/activity/domain/repositories/activity_repository.dart';
import '../../features/activity/domain/usecases/activity_usecases.dart';
import '../../features/activity/presentation/bloc/activity_bloc.dart';

// Analytics feature
import '../../features/performance_dashboard/data/datasources/analytics_mock_datasource.dart';
import '../../features/performance_dashboard/data/repositories/analytics_repository_impl.dart';
import '../../features/performance_dashboard/domain/repositories/analytics_repository.dart';
import '../../features/performance_dashboard/domain/usecases/get_sales_metrics_usecase.dart';
import '../../features/performance_dashboard/presentation/bloc/analytics_bloc.dart';

// Notifications feature
import '../../features/notifications/data/datasources/notification_mock_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';

final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ─── Core ────────────────────────────────────────────
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);

  final authInterceptor = AuthInterceptor(
    secureStorage: secureStorage,
    onRefreshToken: () async {
      final result = await sl<AuthRepository>().refreshToken();
      return result.fold((_) => null, (token) => token);
    },
  );
  sl.registerLazySingleton<AuthInterceptor>(() => authInterceptor);

  final dioClient = DioClient(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: "http://192.168.0.187:8000/api/v1",
      // 'https://api.saleshub.example.com/api/v1',
    ),
    authInterceptor: authInterceptor,
  );
  sl.registerLazySingleton<DioClient>(() => dioClient);

  sl.registerLazySingleton<AuthNotifier>(() => AuthNotifier());

  // ─── Auth Feature ────────────────────────────────────
  // Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // ─── Leads Feature ──────────────────────────────────
  sl.registerLazySingleton<LeadRemoteDataSource>(
    () => LeadRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<LeadRepository>(
    () => LeadRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetLeadsUseCase(sl()));
  sl.registerLazySingleton(() => GetLeadByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateLeadUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLeadUseCase(sl()));
  sl.registerLazySingleton(() => ConvertLeadToAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteLeadUseCase(sl()));
  sl.registerLazySingleton(() => LogLeadActivityUseCase(sl()));
  sl.registerFactory(() => LeadsListBloc(getLeadsUseCase: sl()));
  sl.registerFactory(
    () => LeadDetailBloc(
      getLeadByIdUseCase: sl(),
      convertLeadUseCase: sl(),
      deleteLeadUseCase: sl(),
    ),
  );

  // ─── Users Feature ──────────────────────────────────
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetUsersUseCase(sl()));

  // ─── Accounts Feature ───────────────────────────────
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountMockDataSource(),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAccountsUseCase(sl()));
  sl.registerLazySingleton(() => GetAccountByIdUseCase(sl()));
  sl.registerFactory(() => AccountsListBloc(getAccountsUseCase: sl()));
  sl.registerFactory(() => AccountDetailBloc(getAccountByIdUseCase: sl()));

  // ─── Deals Feature ──────────────────────────────────
  sl.registerLazySingleton<DealRemoteDataSource>(() => DealMockDataSource());
  sl.registerLazySingleton<DealRepository>(
    () => DealRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetDealsUseCase(sl()));
  sl.registerLazySingleton(() => GetDealByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateDealUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDealStageUseCase(sl()));
  sl.registerFactory(() => DealsListBloc(getDealsUseCase: sl()));
  sl.registerFactory(
    () =>
        DealDetailBloc(getDealByIdUseCase: sl(), updateDealStageUseCase: sl()),
  );
  // ─── Checklist Feature ──────────────────────────────
  sl.registerLazySingleton<ChecklistRemoteDataSource>(
    () => ChecklistMockDataSource(),
  );
  sl.registerLazySingleton<ChecklistRepository>(
    () => ChecklistRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetChecklistForDealUseCase(sl()));
  sl.registerLazySingleton(() => ToggleChecklistItemUseCase(sl()));
  sl.registerFactory(
    () => ChecklistBloc(
      getChecklistForDealUseCase: sl(),
      toggleChecklistItemUseCase: sl(),
    ),
  );

  // ─── Activity Feature ──────────────────────────────
  sl.registerLazySingleton<ActivityRemoteDataSource>(
    () => ActivityMockDataSource(),
  );
  sl.registerLazySingleton<ActivityRepository>(
    () => ActivityRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetActivitiesUseCase(sl()));
  sl.registerLazySingleton(() => LogActivityUseCase(sl()));
  sl.registerFactory(
    () => ActivityBloc(getActivitiesUseCase: sl(), logActivityUseCase: sl()),
  );

  // ─── Analytics Feature ─────────────────────────────
  sl.registerLazySingleton<AnalyticsRemoteDataSource>(
    () => AnalyticsMockDataSource(),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetSalesMetricsUseCase(sl()));
  sl.registerFactory(() => AnalyticsBloc(getSalesMetricsUseCase: sl()));

  // ─── Notifications Feature ─────────────────────────
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationMockDataSource(),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerFactory(
    () => NotificationBloc(
      getNotificationsUseCase: sl(),
      getUnreadCountUseCase: sl(),
      markNotificationReadUseCase: sl(),
      markAllNotificationsReadUseCase: sl(),
    ),
  );
}
