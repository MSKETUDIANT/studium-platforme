import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ambassador_remote_datasource.dart';
import '../../data/repositories/ambassador_repository_impl.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/commission.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

//  Infrastructure

final ambassadorDatasourceProvider = Provider<AmbassadorRemoteDatasource>(
  (ref) => AmbassadorRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final ambassadorRepositoryProvider = Provider<AmbassadorRepositoryImpl>(
  (ref) => AmbassadorRepositoryImpl(ref.watch(ambassadorDatasourceProvider)),
);

//  Code de parrainage

final referralCodeProvider = FutureProvider.autoDispose<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(ambassadorRepositoryProvider).ensureReferralCode();
});

//  Filleuls

final myReferralsProvider = FutureProvider.autoDispose<List<Referral>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.watch(ambassadorRepositoryProvider).fetchMyReferrals(userId);
});

//  Commissions

final myCommissionsProvider =
    AsyncNotifierProvider.autoDispose<MyCommissionsNotifier, List<Commission>>(
  MyCommissionsNotifier.new,
);

class MyCommissionsNotifier extends AutoDisposeAsyncNotifier<List<Commission>> {
  @override
  Future<List<Commission>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return ref.watch(ambassadorRepositoryProvider).fetchMyCommissions(userId);
  }

  Future<void> requestPayout(Commission commission) async {
    await ref
        .read(ambassadorRepositoryProvider)
        .requestPayout(commission.id, commission.amount);
  }
}
