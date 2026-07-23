import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SearchResult>>> search(String query) async {
    try {
      return Right(await remoteDataSource.search(query));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
