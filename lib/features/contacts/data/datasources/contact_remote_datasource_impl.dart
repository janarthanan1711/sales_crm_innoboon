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
  Future<Contact> createContact({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    required int accountId,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.contacts,
        data: ContactModel.toCreateJson(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          jobTitle: jobTitle,
          accountId: accountId,
        ),
      );
      return ContactModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Contact> updateContact(
    int id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
  }) async {
    try {
      final response = await dioClient.patch(
        ApiEndpoints.contactById('$id'),
        data: ContactModel.toUpdateJson(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phone: phone,
          jobTitle: jobTitle,
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
