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
      return leadActivityFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<LeadActivity>> listActivities(
    int leadId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.leadActivities('$leadId'),
        queryParameters: {
          if (types != null && types.isNotEmpty) 'types': types,
          if (dateFrom != null) 'date_from': _formatDate(dateFrom),
          if (dateTo != null) 'date_to': _formatDate(dateTo),
        },
      );
      final data = response.data as List<dynamic>;
      return data
          .map((json) => leadActivityFromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<LeadActivity> updateActivity(
    int leadId,
    int activityId, {
    String? type,
    String? note,
  }) async {
    try {
      final response = await dioClient.patch(
        '${ApiEndpoints.leadActivities('$leadId')}/$activityId',
        data: {
          if (type != null) 'type': type,
          if (note != null) 'note': note,
        },
      );
      return leadActivityFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteActivity(int leadId, int activityId) async {
    try {
      await dioClient.delete(
        '${ApiEndpoints.leadActivities('$leadId')}/$activityId',
      );
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
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
