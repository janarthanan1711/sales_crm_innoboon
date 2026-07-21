import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/usecases/lead_upsert_params.dart';
import '../models/lead_model.dart';

/// Real API implementation of LeadRemoteDataSource — talks to
/// `saleshub`'s `/leads` router (see app/api/v1/leads.py).
class LeadRemoteDataSourceImpl implements LeadRemoteDataSource {
  final DioClient dioClient;

  LeadRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<({List<Lead> items, int total})> getLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.leads,
        queryParameters: {
          if (ownerId != null) 'owner_id': ownerId,
          if (source != null) 'source': source,
          if (status != null) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': limit,
          'offset': offset,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((json) => LeadModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return (items: items, total: data['total'] as int);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Lead> getLeadById(int id) async {
    try {
      final response = await dioClient.get(ApiEndpoints.leadById('$id'));
      return LeadModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Lead> createLead(LeadUpsertParams params) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.leads,
        data: LeadModel.toUpsertJson(params),
      );
      return LeadModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Lead> updateLead(int id, LeadUpsertParams params) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.leads,
        data: LeadModel.toUpsertJson(params, id: id),
      );
      return LeadModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteLead(int id) async {
    try {
      await dioClient.delete(ApiEndpoints.leadById('$id'));
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<int> convertToAccount(int leadId, {String? tier, int? ownerId}) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.convertLead('$leadId'),
        data: {
          if (tier != null) 'tier': tier,
          if (ownerId != null) 'owner_id': ownerId,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['id'] as int;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<LeadActivity> logActivity(
    int leadId, {
    required String type,
    required String note,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.leadActivities('$leadId'),
        data: {'type': type, 'note': note},
      );
      final data = response.data as Map<String, dynamic>;
      return LeadActivity(
        id: data['id'] as int,
        leadId: data['lead_id'] as int,
        type: data['type'] as String,
        note: data['note'] as String,
        createdBy: data['created_by'] as int,
        createdAt: DateTime.parse(data['created_at'] as String),
      );
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
