import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';
import '../models/contact_model.dart';

class ContactRemoteDataSourceImpl implements ContactRemoteDataSource {
  final DioClient dioClient;

  ContactRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<Contact> getContactById(int id) async {
    try {
      final response = await dioClient.get(ApiEndpoints.contactById('$id'));
      return ContactModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Contact> upsertAccountContact({
    required int accountId,
    int? contactId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? alternatePhone,
    String? jobTitle,
    String? linkedinUrl,
    bool? isPrimary,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.accountContacts('$accountId'),
        data: ContactModel.toUpsertJson(
          contactId: contactId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          alternatePhone: alternatePhone,
          jobTitle: jobTitle,
          linkedinUrl: linkedinUrl,
          isPrimary: isPrimary,
        ),
      );
      return ContactModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteContact(int id) async {
    try {
      await dioClient.delete(ApiEndpoints.contactById('$id'));
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
