import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/application_remote_datasource.dart';
import '../../data/repositories/application_repository_impl.dart';
import '../../domain/entities/application.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

//  Status History 

final statusHistoryProvider = FutureProvider.autoDispose
    .family<List<StatusHistoryEntry>, String>((ref, applicationId) {
  return ref
      .read(applicationDatasourceProvider)
      .fetchStatusHistory(applicationId);
});

//  Infrastructure 

final applicationDatasourceProvider = Provider<ApplicationRemoteDatasource>(
  (ref) => ApplicationRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final applicationRepositoryProvider = Provider<ApplicationRepositoryImpl>(
  (ref) => ApplicationRepositoryImpl(ref.watch(applicationDatasourceProvider)),
);

//  My Applications 

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

    final client = ref.watch(supabaseClientProvider);
    final channel = client
        .channel('my-applications-$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.update,
          schema: 'public',
          table:  'applications',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'student_profile_id',
            value:  userId,
          ),
          callback: (_) => ref.invalidateSelf(),
        )
        .subscribe();
    ref.onDispose(() => client.removeChannel(channel));

    return ref
        .read(applicationRepositoryProvider)
        .fetchMyApplications(userId);
  }

  Future<Application?> submit({
    required String programId,
    List<String> documentIds = const [],
    String? motivationLetter,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;
    final app = await ref
        .read(applicationRepositoryProvider)
        .createApplication(
          studentProfileId: userId,
          programId:        programId,
          documentIds:      documentIds,
          motivationLetter: motivationLetter,
        );
    ref.invalidateSelf();
    return app;
  }

  Future<Application?> saveDraft({
    required String programId,
    String? motivationLetter,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;
    final app = await ref.read(applicationRepositoryProvider).createApplication(
          studentProfileId: userId,
          programId:        programId,
          draft:            true,
          motivationLetter: motivationLetter,
        );
    ref.invalidateSelf();
    return app;
  }

  Future<void> submitDraft(
    String applicationId, {
    List<String> documentIds = const [],
    String? motivationLetter,
  }) async {
    await ref.read(applicationRepositoryProvider).submitDraft(
          applicationId,
          documentIds: documentIds,
          motivationLetter: motivationLetter,
        );
    ref.invalidateSelf();
  }

  Future<void> resubmit(String applicationId) async {
    await ref.read(applicationRepositoryProvider).resubmit(applicationId);
    ref.invalidateSelf();
  }
}
