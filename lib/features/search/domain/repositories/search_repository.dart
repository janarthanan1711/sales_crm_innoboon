import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<SearchResult>>> search(String query);
}

abstract class SearchRemoteDataSource {
  Future<List<SearchResult>> search(String query);
}
