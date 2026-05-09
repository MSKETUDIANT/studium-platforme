import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';
import '../datasources/program_remote_datasource.dart';

class ProgramRepositoryImpl implements ProgramRepository {
  final ProgramRemoteDatasource _datasource;
  const ProgramRepositoryImpl(this._datasource);

  @override
  Future<List<Program>> getPrograms() => _datasource.getPrograms();
}
