import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../../domain/repositories/deal_repository.dart';
import '../models/deal_model.dart';
import '../models/deal_stage_def_model.dart';

/// Real API implementation of DealRemoteDataSource — talks to `saleshub`'s
/// `/deals` router. Stages are dynamic (`stage_id` → `/deal-stages`); stage
/// changes go through the same `PATCH /deals/{id}` as any other update
/// (the `note` is written to the resulting stage-history row).
class DealRemoteDataSourceImpl implements DealRemoteDataSource {
  final DioClient dioClient;

  DealRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<Deal>> getDeals({
    int? ownerId,
    String? accountId,
    int? stageId,
    String? search,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.deals,
        queryParameters: {
          'view': 'list',
          if (ownerId != null) 'owner_id': ownerId,
          if (accountId != null) 'account_id': accountId,
          if (stageId != null) 'stage_id': stageId,
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': 200,
          'offset': 0,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      return items
          .map((e) => DealModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Deal> getDealById(String id) async {
    try {
      final response = await dioClient.get(ApiEndpoints.dealById(id));
      return DealModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Deal> createDeal({
    required String dealName,
    required String accountId,
    required double value,
    String currency = 'INR',
    DateTime? expectedCloseDate,
    required int stageId,
    List<int>? contactIds,
    String? tier,
    String? coldReason,
    int? ownerId,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.deals,
        data: DealModel.toCreateJson(
          dealName: dealName,
          accountId: accountId,
          value: value,
          currency: currency,
          expectedCloseDate: expectedCloseDate,
          stageId: stageId,
          contactIds: contactIds,
          tier: tier,
          coldReason: coldReason,
          ownerId: ownerId,
        ),
      );
      return DealModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Deal> updateDeal(
    String id, {
    String? dealName,
    double? value,
    String? currency,
    DateTime? expectedCloseDate,
    int? stageId,
    List<int>? contactIds,
    String? coldReason,
    int? ownerId,
    String? note,
  }) async {
    try {
      final response = await dioClient.patch(
        ApiEndpoints.dealById(id),
        data: DealModel.toUpdateJson(
          dealName: dealName,
          value: value,
          currency: currency,
          expectedCloseDate: expectedCloseDate,
          stageId: stageId,
          contactIds: contactIds,
          coldReason: coldReason,
          ownerId: ownerId,
          note: note,
        ),
      );
      return DealModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<DealStageHistoryEntry>> getStageHistory(String id) async {
    try {
      final response = await dioClient.get(ApiEndpoints.dealStageHistory(id));
      final items = response.data as List<dynamic>;
      return items
          .map((e) => DealStageHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<DealStageDef>> getDealStages() async {
    try {
      final response = await dioClient.get(ApiEndpoints.dealStages);
      final items = response.data as List<dynamic>;
      final stages = items
          .map((e) => dealStageDefFromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return stages;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  Exception _normalize(DioException e) {
    final normalized = e.error;
    if (normalized is Exception) return normalized;
    return ServerException(
      message: e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
