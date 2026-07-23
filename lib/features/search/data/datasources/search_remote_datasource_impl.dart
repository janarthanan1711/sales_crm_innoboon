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
      return _parse(response.data);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  /// Accepts any of the shapes the backend might return:
  ///  - a raw list: `[ {type,id,label}, ... ]`
  ///  - an envelope: `{ "items"|"results"|"data": [ ... ] }`
  ///  - grouped by type: `{ "leads": [...], "accounts": [...], ... }`
  List<SearchResult> _parse(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => searchResultFromJson(e))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      // Envelope with a single list under a common key.
      for (final key in const ['items', 'results', 'data', 'hits']) {
        final v = data[key];
        if (v is List) {
          return v
              .whereType<Map<String, dynamic>>()
              .map((e) => searchResultFromJson(e))
              .toList();
        }
      }
      // Grouped-by-type object: each key names a type, value is a list.
      final out = <SearchResult>[];
      data.forEach((key, value) {
        if (value is List) {
          final hint = searchResultTypeFromWire(key);
          out.addAll(value
              .whereType<Map<String, dynamic>>()
              .map((e) => searchResultFromJson(e, typeHint: hint)));
        }
      });
      return out;
    }
    return const [];
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
