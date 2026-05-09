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
