import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';
import '../datasources/program_remote_datasource.dart';

class ProgramRepositoryImpl implements ProgramRepository {
  final ProgramRemoteDatasource _datasource;
  const ProgramRepositoryImpl(this._datasource);

  @override
  Future<List<Program>> getPrograms() => _datasource.getPrograms();

  @override
  Future<Set<String>> fetchFavoriteIds(String studentProfileId) =>
      _datasource.fetchFavoriteIds(studentProfileId);

  @override
  Future<void> addFavorite(String studentProfileId, String programId) =>
      _datasource.addFavorite(studentProfileId, programId);

  @override
  Future<void> removeFavorite(String studentProfileId, String programId) =>
      _datasource.removeFavorite(studentProfileId, programId);
}
