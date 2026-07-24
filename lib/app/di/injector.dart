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
import '../../features/auth/domain/usecases/profile_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Roles feature
import '../../features/roles/data/datasources/role_remote_datasource_impl.dart';
import '../../features/roles/data/repositories/role_repository_impl.dart';
import '../../features/roles/domain/repositories/role_repository.dart';
import '../../features/roles/domain/usecases/role_usecases.dart';

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
import '../../features/leads/domain/usecases/list_lead_activities_usecase.dart';
import '../../features/leads/domain/usecases/update_lead_activity_usecase.dart';
import '../../features/leads/domain/usecases/delete_lead_activity_usecase.dart';
import '../../features/leads/domain/usecases/import_leads_usecase.dart';
import '../../features/leads/domain/usecases/download_import_template_usecase.dart';
import '../../features/leads/presentation/bloc/leads_list_bloc.dart';
import '../../features/leads/presentation/bloc/lead_detail_bloc.dart';

// Users feature
import '../../features/users/data/datasources/user_remote_datasource.dart';
import '../../features/users/data/repositories/user_repository_impl.dart';
import '../../features/users/domain/repositories/user_repository.dart';
import '../../features/users/domain/usecases/get_users_usecase.dart';
import '../../features/users/domain/usecases/create_user_usecase.dart';
import '../../features/users/domain/usecases/delete_user_usecase.dart';

// Accounts feature
import '../../features/accounts/data/datasources/account_remote_datasource_impl.dart';
import '../../features/accounts/data/repositories/account_repository_impl.dart';
import '../../features/accounts/domain/repositories/account_repository.dart';
import '../../features/accounts/domain/usecases/get_accounts_usecase.dart';
import '../../features/accounts/domain/usecases/get_account_by_id_usecase.dart';
import '../../features/accounts/domain/usecases/create_account_usecase.dart';
import '../../features/accounts/domain/usecases/update_account_usecase.dart';
import '../../features/accounts/domain/usecases/get_account_contacts_usecase.dart';
import '../../features/accounts/domain/usecases/get_account_overview_usecase.dart';
import '../../features/accounts/presentation/bloc/accounts_list_bloc.dart';
import '../../features/accounts/presentation/bloc/account_detail_bloc.dart';

// Contacts feature
import '../../features/contacts/data/datasources/contact_remote_datasource_impl.dart';
import '../../features/contacts/data/repositories/contact_repository_impl.dart';
import '../../features/contacts/domain/repositories/contact_repository.dart';
import '../../features/contacts/domain/usecases/contact_usecases.dart';
import '../../features/contacts/presentation/bloc/contacts_list_bloc.dart';
import '../../features/contacts/presentation/bloc/contact_detail_bloc.dart';

// Deals feature
import '../../features/deals/data/datasources/deal_remote_datasource_impl.dart';
import '../../features/deals/data/repositories/deal_repository_impl.dart';
import '../../features/deals/domain/repositories/deal_repository.dart';
import '../../features/deals/domain/usecases/get_deals_usecase.dart';
import '../../features/deals/domain/usecases/get_deal_by_id_usecase.dart';
import '../../features/deals/domain/usecases/create_deal_usecase.dart';
import '../../features/deals/domain/usecases/update_deal_usecase.dart';
import '../../features/deals/domain/usecases/update_deal_stage_usecase.dart';
import '../../features/deals/domain/usecases/get_deal_stage_history_usecase.dart';
import '../../features/deals/domain/usecases/get_deal_stages_usecase.dart';
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
import '../../features/notifications/data/datasources/notification_remote_datasource_impl.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/documents/data/datasources/document_mock_datasource.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/documents/domain/usecases/get_account_documents_usecase.dart';
import '../../features/search/data/datasources/search_remote_datasource_impl.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/global_search_usecase.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';

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
      defaultValue:
          //  "https://dollar-starry-worry.ngrok-free.dev/api/v1",
          "http://192.168.0.187:8000/api/v1",
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
  sl.registerLazySingleton(() => FetchCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  // ─── Roles Feature ───────────────────────────────────
  sl.registerLazySingleton<RoleRemoteDataSource>(
    () => RoleRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<RoleRepository>(
    () => RoleRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => ListPermissionsUseCase(sl()));
  sl.registerLazySingleton(() => ListRolesUseCase(sl()));
  sl.registerLazySingleton(() => CreateRoleUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRoleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRoleUseCase(sl()));

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
  sl.registerLazySingleton(() => ListLeadActivitiesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateLeadActivityUseCase(sl()));
  sl.registerLazySingleton(() => DeleteLeadActivityUseCase(sl()));
  sl.registerLazySingleton(() => ImportLeadsUseCase(sl()));
  sl.registerLazySingleton(() => DownloadImportTemplateUseCase(sl()));
  sl.registerFactory(() => LeadsListBloc(getLeadsUseCase: sl()));
  sl.registerFactory(
    () => LeadDetailBloc(
      getLeadByIdUseCase: sl(),
      convertLeadUseCase: sl(),
      deleteLeadUseCase: sl(),
      listLeadActivitiesUseCase: sl(),
      logLeadActivityUseCase: sl(),
      updateLeadActivityUseCase: sl(),
      deleteLeadActivityUseCase: sl(),
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
  sl.registerLazySingleton(() => CreateUserUseCase(sl()));
  sl.registerLazySingleton(() => DeleteUserUseCase(sl()));

  // ─── Accounts Feature ───────────────────────────────
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAccountsUseCase(sl()));
  sl.registerLazySingleton(() => GetAccountByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateAccountUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetAccountContactsUseCase(sl()));
  sl.registerLazySingleton(() => GetAccountOverviewUseCase(sl()));
  sl.registerFactory(() => AccountsListBloc(getAccountsUseCase: sl()));
  sl.registerFactory(
    () => AccountDetailBloc(
      getAccountOverviewUseCase: sl(),
      getAccountContactsUseCase: sl(),
    ),
  );

  // ─── Contacts Feature ───────────────────────────────
  sl.registerLazySingleton<ContactRemoteDataSource>(
    () => ContactRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => UpsertAccountContactUseCase(sl()));
  sl.registerLazySingleton(() => DeleteContactUseCase(sl()));
  sl.registerLazySingleton(() => GetContactsUseCase(sl()));
  sl.registerLazySingleton(() => GetContactByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetContactOverviewUseCase(sl()));
  sl.registerLazySingleton(() => GetContactDealsUseCase(sl()));
  sl.registerFactory(
    () =>
        ContactsListBloc(getContactsUseCase: sl(), deleteContactUseCase: sl()),
  );
  sl.registerFactory(
    () => ContactDetailBloc(
      getContactOverviewUseCase: sl(),
      getContactDealsUseCase: sl(),
    ),
  );

  // ─── Deals Feature ──────────────────────────────────
  sl.registerLazySingleton<DealRemoteDataSource>(
    () => DealRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<DealRepository>(
    () => DealRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetDealsUseCase(sl()));
  sl.registerLazySingleton(() => GetDealByIdUseCase(sl()));
  sl.registerLazySingleton(() => CreateDealUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDealUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDealStageUseCase(sl()));
  sl.registerLazySingleton(() => GetDealStageHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetDealStagesUseCase(sl()));
  sl.registerFactory(
    () => DealsListBloc(
      getDealsUseCase: sl(),
      getDealStagesUseCase: sl(),
      updateDealStageUseCase: sl(),
      getAccountsUseCase: sl(),
      getUsersUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => DealDetailBloc(
      getDealByIdUseCase: sl(),
      getDealStagesUseCase: sl(),
      updateDealStageUseCase: sl(),
      getDealStageHistoryUseCase: sl(),
      getAccountByIdUseCase: sl(),
      getUsersUseCase: sl(),
    ),
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
    () => NotificationRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationUnreadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkManyNotificationsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationsUseCase(sl()));
  sl.registerFactory(
    () => NotificationBloc(
      getNotificationsUseCase: sl(),
      getUnreadCountUseCase: sl(),
      markNotificationReadUseCase: sl(),
      markNotificationUnreadUseCase: sl(),
      markAllNotificationsReadUseCase: sl(),
      markManyNotificationsReadUseCase: sl(),
      deleteNotificationsUseCase: sl(),
    ),
  );

  // ─── Documents Feature (mock-backed) ────────────────
  sl.registerLazySingleton<DocumentDataSource>(() => DocumentMockDataSource());
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAccountDocumentsUseCase(sl()));

  // ─── Search Feature ─────────────────────────────────
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GlobalSearchUseCase(sl()));
  sl.registerFactory(() => SearchBloc(globalSearchUseCase: sl()));
}
