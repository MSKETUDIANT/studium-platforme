import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/application_remote_datasource.dart';
import '../../data/repositories/application_repository_impl.dart';
import '../../domain/entities/application.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final applicationDatasourceProvider = Provider<ApplicationRemoteDatasource>(
  (ref) => ApplicationRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final applicationRepositoryProvider = Provider<ApplicationRepositoryImpl>(
  (ref) => ApplicationRepositoryImpl(ref.watch(applicationDatasourceProvider)),
);

// ─── My Applications ─────────────────────────────────────────────────────────

final myApplicationsProvider =
    AsyncNotifierProvider.autoDispose<MyApplicationsNotifier, List<Application>>(
  MyApplicationsNotifier.new,
);

class MyApplicationsNotifier
    extends AutoDisposeAsyncNotifier<List<Application>> {
  @override
  Future<List<Application>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return ref
        .read(applicationRepositoryProvider)
        .fetchMyApplications(userId);
  }

  Future<Application?> submit({required String programId}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;
    final app = await ref
        .read(applicationRepositoryProvider)
        .createApplication(
          studentProfileId: userId,
          programId:        programId,
        );
    ref.invalidateSelf();
    return app;
  }
}
