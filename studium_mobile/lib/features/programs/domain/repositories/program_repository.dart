import '../entities/program.dart';

abstract class ProgramRepository {
  Future<List<Program>> getPrograms();
}
