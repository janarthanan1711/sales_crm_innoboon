import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../models/search_result_model.dart';

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final DioClient dioClient;

  SearchRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<SearchResult>> search(String query) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => searchResultFromJson(e as Map<String, dynamic>))
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
