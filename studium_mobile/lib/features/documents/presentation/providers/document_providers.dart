import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/document_remote_datasource.dart';
import '../../data/repositories/document_repository_impl.dart'
    show DocumentRepositoryImpl;
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final documentDatasourceProvider = Provider<DocumentRemoteDatasource>(
  (ref) => DocumentRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(ref.watch(documentDatasourceProvider)),
);

// ─── Documents ────────────────────────────────────────────────────────────────

final documentsProvider =
    AsyncNotifierProvider.autoDispose<DocumentsNotifier, List<Document>>(
  DocumentsNotifier.new,
);

class DocumentsNotifier extends AutoDisposeAsyncNotifier<List<Document>> {
  @override
  Future<List<Document>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return ref.read(documentRepositoryProvider).getDocuments(userId);
  }

  Future<void> upload({
    required DocumentType type,
    required String filePath,
  }) async {
    final userId = ref.read(currentUserIdProvider) ?? '';
    await ref.read(documentRepositoryProvider).uploadDocument(
      studentProfileId: userId,
      type: type,
      filePath: filePath,
    );
    ref.invalidateSelf();
    ref.invalidate(documentCountProvider);
  }

  Future<void> delete(String documentId, String fileUrl) async {
    await AsyncValue.guard(
      () => ref.read(documentRepositoryProvider).deleteDocument(
            documentId,
            fileUrl,
          ),
    );
    ref.invalidateSelf();
    ref.invalidate(documentCountProvider);
  }
}