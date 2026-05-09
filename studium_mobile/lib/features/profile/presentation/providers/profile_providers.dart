import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart' as data_repo;

import '../../domain/entities/academic_background.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/profile_repository.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final profileDatasourceProvider = Provider<ProfileRemoteDatasource>(
  (ref) => ProfileRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => data_repo.ProfileRepositoryImpl(ref.watch(profileDatasourceProvider)),
);

// ─── Current user ID ─────────────────────────────────────────────────────────

final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// ─── Student Profile ─────────────────────────────────────────────────────────

final profileProvider = FutureProvider.autoDispose<StudentProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});

final profileNotifierProvider =
    AsyncNotifierProvider.autoDispose<ProfileNotifier, StudentProfile?>(
  ProfileNotifier.new,
);

int _computeCompletenessScore({
  required StudentProfile profile,
  required int academicsCount,
  required int experiencesCount,
  required int documentsCount,
}) {
  int score = 0;
  final hasInfos = (profile.firstName?.isNotEmpty ?? false) &&
      (profile.lastName?.isNotEmpty ?? false) &&
      profile.nationality != null;
  if (hasInfos) score += 25;
  if (academicsCount > 0) score += 25;
  if (experiencesCount > 0) score += 25;
  if (documentsCount > 0) score += 25;
  return score;
}

class ProfileNotifier extends AutoDisposeAsyncNotifier<StudentProfile?> {
  @override
  Future<StudentProfile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;

    // Recompute score whenever academics, experiences or documents change
    ref.listen(academicBackgroundsProvider, (_, next) {
      if (next.hasValue) refreshScore();
    });
    ref.listen(experiencesProvider, (_, next) {
      if (next.hasValue) refreshScore();
    });
    ref.listen(documentCountProvider, (_, next) {
      if (next.hasValue) refreshScore();
    });

    return ref.read(profileRepositoryProvider).getProfile(userId);
  }

  Future<void> upsert(StudentProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).upsertProfile(profile),
    );
    await refreshScore();
  }

  Future<void> refreshScore() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final repo   = ref.read(profileRepositoryProvider);
    final client = ref.read(supabaseClientProvider);

    final academics   = await repo.getAcademicBackgrounds(current.id);
    final experiences = await repo.getExperiences(current.id);
    final docs        = await client
        .from('documents')
        .select('id')
        .eq('student_profile_id', current.id);

    final score = _computeCompletenessScore(
      profile:          current,
      academicsCount:   academics.length,
      experiencesCount: experiences.length,
      documentsCount:   (docs as List).length,
    );

    if (score == current.completenessScore) return;

    final updated = current.copyWith(completenessScore: score);
    state = await AsyncValue.guard(
      () => repo.upsertProfile(updated),
    );
  }

  Future<void> updatePhoto(String userId, String imagePath) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updatePhoto(userId, imagePath),
    );
    ref.invalidateSelf();
  }

  Future<void> deletePhoto(String userId) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).deletePhoto(userId),
    );
    ref.invalidateSelf();
  }
}

// ─── Dashboard stats ─────────────────────────────────────────────────────────

final documentCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  final data = await ref
      .read(supabaseClientProvider)
      .from('documents')
      .select('id')
      .eq('student_profile_id', userId);
  return (data as List).length;
});

// ─── Academic Backgrounds ────────────────────────────────────────────────────

final academicBackgroundsProvider =
    AsyncNotifierProvider.autoDispose<AcademicBackgroundsNotifier, List<AcademicBackground>>(
  AcademicBackgroundsNotifier.new,
);

class AcademicBackgroundsNotifier
    extends AutoDisposeAsyncNotifier<List<AcademicBackground>> {
  @override
  Future<List<AcademicBackground>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return ref.read(profileRepositoryProvider).getAcademicBackgrounds(userId);
  }

  Future<void> add(AcademicBackground background) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).addAcademicBackground(background),
    );
    ref.invalidateSelf();
  }

  Future<void> updateItem(AcademicBackground background) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateAcademicBackground(background),
    );
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).deleteAcademicBackground(id),
    );
    ref.invalidateSelf();
  }
}

// ─── Experiences ─────────────────────────────────────────────────────────────

final experiencesProvider =
    AsyncNotifierProvider.autoDispose<ExperiencesNotifier, List<Experience>>(
  ExperiencesNotifier.new,
);

class ExperiencesNotifier extends AutoDisposeAsyncNotifier<List<Experience>> {
  @override
  Future<List<Experience>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return ref.read(profileRepositoryProvider).getExperiences(userId);
  }

  Future<void> add(Experience experience) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).addExperience(experience),
    );
    ref.invalidateSelf();
  }

  Future<void> updateItem(Experience experience) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateExperience(experience),
    );
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).deleteExperience(id),
    );
    ref.invalidateSelf();
  }
}