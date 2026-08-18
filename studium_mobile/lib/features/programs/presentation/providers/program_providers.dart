import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/program_remote_datasource.dart';
import '../../data/repositories/program_repository_impl.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/domain/entities/student_profile.dart';
import '../../../profile/domain/entities/academic_background.dart';
import '../../../applications/domain/entities/application.dart';
import '../../../applications/presentation/providers/application_providers.dart';

final programDatasourceProvider = Provider<ProgramRemoteDatasource>(
  (ref) => ProgramRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => ProgramRepositoryImpl(ref.watch(programDatasourceProvider)),
);

final programsProvider = FutureProvider.autoDispose<List<Program>>((ref) {
  return ref.read(programRepositoryProvider).getPrograms();
});

//  Recommandations

const int _kMaxRecommendations = 10;

final recommendedProgramsProvider =
    FutureProvider.autoDispose<List<Program>>((ref) async {
  final programs     = await ref.watch(programsProvider.future);
  final profile      = await ref.watch(profileProvider.future);
  final academics    = await ref.watch(academicBackgroundsProvider.future);
  final applications = await ref.watch(myApplicationsProvider.future);
  final favoriteIds  = await ref.watch(favoriteProgramIdsProvider.future);

  return computeRecommendations(
    allPrograms:  programs,
    profile:      profile,
    academics:    academics,
    applications: applications,
    favoriteIds:  favoriteIds,
  );
});

@visibleForTesting
List<Program> computeRecommendations({
  required List<Program> allPrograms,
  required StudentProfile? profile,
  required List<AcademicBackground> academics,
  required List<Application> applications,
  required Set<String> favoriteIds,
}) {
  final now = DateTime.now();
  final appliedProgramIds = applications.map((a) => a.programId).toSet();

  // Dernier diplôme obtenu (année la plus récente) : sert à la fois à
  // inférer le niveau visé et à comparer la moyenne de l'étudiant aux
  // exigences des programmes (recommandations réellement prédictives,
  // pas seulement basées sur des préférences déclarées).
  // Boucle explicite plutôt que .reduce() : la liste est en réalité un
  // List<AcademicBackgroundModel> (covariance Dart), et le closure de
  // reduce() y est alors rejeté au runtime ("not a subtype of ... combine").
  AcademicBackground? latestAcademic;
  for (final a in academics) {
    if (latestAcademic == null || (a.year ?? 0) >= (latestAcademic.year ?? 0)) {
      latestAcademic = a;
    }
  }
  final studentAverage = latestAcademic?.average;

  final candidates = allPrograms.where((p) =>
      p.isActive &&
      !p.isExpired &&
      !appliedProgramIds.contains(p.id) &&
      !favoriteIds.contains(p.id) &&
      p.isEligibleFor(studentAverage) != false).toList();

  if (candidates.isEmpty) return [];

  int soonestDeadlineFirst(Program a, Program b) {
    final da = a.deadline, db = b.deadline;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  final levelWeights   = <String, double>{};
  final countryWeights = <String, double>{};
  final domainWeights  = <String, double>{};

  void bump(Map<String, double> m, String? key, double weight) {
    if (key == null || key.isEmpty) return;
    m[key] = (m[key] ?? 0) + weight;
  }

  for (final a in applications) {
    bump(levelWeights, a.level, 3);
    bump(countryWeights, a.country, 2);
  }

  final programById = {for (final p in allPrograms) p.id: p};
  for (final favId in favoriteIds) {
    final p = programById[favId];
    if (p == null) continue;
    bump(levelWeights, p.level, 2);
    bump(countryWeights, p.country, 2);
    bump(domainWeights, p.domain, 2);
  }

  // Infère le niveau visé depuis le dernier diplôme obtenu
  if (latestAcademic != null) {
    final degree = latestAcademic.degree.toLowerCase();
    if (degree.contains('master') || degree.contains('bac+5')) {
      bump(levelWeights, 'phd', 2);
    } else if (degree.contains('licence') ||
        degree.contains('bachelor') ||
        degree.contains('bac+3')) {
      bump(levelWeights, 'master', 2);
    } else {
      bump(levelWeights, 'bachelor', 1);
    }
  }

  bump(countryWeights, profile?.countryResidence, 1);

  final goalsText =
      '${profile?.academicGoals ?? ''} ${profile?.careerGoals ?? ''}'
          .toLowerCase();
  final goalWords = goalsText
      .split(RegExp(r'[^a-zàâäéèêëîïôöùûüç]+'))
      .where((w) => w.length > 3)
      .toSet();

  double score(Program p) {
    double s = 0;
    s += levelWeights[p.level] ?? 0;
    s += countryWeights[p.country] ?? 0;
    s += (domainWeights[p.domain] ?? 0) * 1.5;

    if (goalWords.isNotEmpty) {
      final text = '${p.domain ?? ''} ${p.description ?? ''} ${p.programName}'
          .toLowerCase();
      final matches = goalWords.where(text.contains).length;
      s += matches * 0.5;
    }

    final dl = p.deadline;
    if (dl != null) {
      final days = dl.difference(now).inDays;
      if (days >= 0 && days <= 60) s += 0.3;
    }

    // Éligibilité confirmée (moyenne connue >= seuil du programme) :
    // priorise les programmes où l'étudiant a une vraie chance, plutôt
    // que de se fier uniquement à ses préférences déclarées.
    if (p.isEligibleFor(studentAverage) == true) s += 1;

    return s;
  }

  final scored = candidates.map((p) => MapEntry(p, score(p))).toList()
    ..sort((a, b) {
      final cmp = b.value.compareTo(a.value);
      return cmp != 0 ? cmp : soonestDeadlineFirst(a.key, b.key);
    });

  final matched = scored.where((e) => e.value > 0).map((e) => e.key).toList();
  if (matched.length >= _kMaxRecommendations) {
    return matched.take(_kMaxRecommendations).toList();
  }

  // Complète avec les deadlines les plus proches pour ne pas laisser
  // la section vide/clairsemée quand le profil manque de signal.
  final seen = matched.toSet();
  final padding = candidates.where((p) => !seen.contains(p)).toList()
    ..sort(soonestDeadlineFirst);

  return [...matched, ...padding].take(_kMaxRecommendations).toList();
}

//  Favorites 

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
