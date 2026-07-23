import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class GlobalSearchUseCase {
  final SearchRepository repository;
  GlobalSearchUseCase(this.repository);

  Future<Either<Failure, List<SearchResult>>> call(String query) =>
      repository.search(query);
}
