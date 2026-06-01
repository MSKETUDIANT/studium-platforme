import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/program_remote_datasource.dart';
import '../../data/repositories/program_repository_impl.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

final programDatasourceProvider = Provider<ProgramRemoteDatasource>(
  (ref) => ProgramRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => ProgramRepositoryImpl(ref.watch(programDatasourceProvider)),
);

final programsProvider = FutureProvider.autoDispose<List<Program>>((ref) {
  return ref.read(programRepositoryProvider).getPrograms();
});

// ─── Favorites ────────────────────────────────────────────────────────────────

final favoriteProgramIdsProvider =
    AsyncNotifierProvider.autoDispose<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AutoDisposeAsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return {};
    return ref.read(programRepositoryProvider).fetchFavoriteIds(userId);
  }

  Future<void> toggle(String programId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final current = state.valueOrNull ?? {};
    if (current.contains(programId)) {
      await ref.read(programRepositoryProvider).removeFavorite(userId, programId);
      state = AsyncData(Set<String>.from(current)..remove(programId));
    } else {
      await ref.read(programRepositoryProvider).addFavorite(userId, programId);
      state = AsyncData({...current, programId});
    }
  }
}
