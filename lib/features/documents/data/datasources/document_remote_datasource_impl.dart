import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/account_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/account_document_model.dart';

/// Real API implementation — talks to `saleshub`'s
/// `/accounts/{account_id}/documents` endpoints. Uploads are multipart with a
/// single `file` field; the server validates the content type (pdf/doc/docx/
/// png/jpeg) and 400s anything else.
class DocumentRemoteDataSourceImpl implements DocumentDataSource {
  final DioClient dioClient;

  DocumentRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<AccountDocument>> getAccountDocuments(String accountId) async {
    try {
      final response =
          await dioClient.get(ApiEndpoints.accountDocuments(accountId));
      final data = response.data as List<dynamic>;
      return data
          .map((e) => accountDocumentFromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<AccountDocument> uploadAccountDocument(
    String accountId, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: _mediaTypeFor(fileName),
        ),
      });
      final response = await dioClient.post(
        ApiEndpoints.accountDocuments(accountId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return accountDocumentFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteAccountDocument(
    String accountId,
    String documentId,
  ) async {
    try {
      await dioClient.delete(
        ApiEndpoints.accountDocumentById(accountId, documentId),
      );
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  /// Best-effort content type from the file extension so the server's
  /// allow-list check passes. Unknown types fall back to octet-stream (the
  /// server then returns a clear 400 "unsupported file type").
  DioMediaType? _mediaTypeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    switch (ext) {
      case 'pdf':
        return DioMediaType('application', 'pdf');
      case 'doc':
        return DioMediaType('application', 'msword');
      case 'docx':
        return DioMediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'png':
        return DioMediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return DioMediaType('image', 'jpeg');
      default:
        return null;
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
