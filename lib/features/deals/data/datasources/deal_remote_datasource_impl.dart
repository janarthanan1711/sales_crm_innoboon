import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../../domain/repositories/deal_repository.dart';
import '../models/deal_model.dart';

/// Real API implementation of DealRemoteDataSource — talks to `saleshub`'s
/// `/deals` router. Stage changes go through the same `PATCH /deals/{id}`
/// as any other update (see [updateDeal]'s `note` param, which is written
/// to the resulting stage-history row, not the deal itself).
class DealRemoteDataSourceImpl implements DealRemoteDataSource {
  final DioClient dioClient;

  DealRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<Deal>> getDeals({
    int? ownerId,
    String? accountId,
    DealStage? stage,
    String? search,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.deals,
        queryParameters: {
          if (ownerId != null) 'owner_id': ownerId,
          if (accountId != null) 'account_id': accountId,
          if (stage != null) 'stage': stage.wireValue,
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': 100,
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
    required DealStage stage,
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
          stage: stage,
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
    DealStage? stage,
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
          stage: stage,
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
          .map(
            (e) => DealStageHistoryEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();
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
