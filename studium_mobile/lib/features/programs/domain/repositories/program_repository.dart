import '../entities/program.dart';

abstract class ProgramRepository {
  Future<List<Program>> getPrograms();
  Future<Set<String>> fetchFavoriteIds(String studentProfileId);
  Future<void> addFavorite(String studentProfileId, String programId);
  Future<void> removeFavorite(String studentProfileId, String programId);
}
