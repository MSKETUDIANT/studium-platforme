import '../../domain/entities/referral.dart';
import '../../domain/entities/commission.dart';
import '../datasources/ambassador_remote_datasource.dart';

class AmbassadorRepositoryImpl {
  final AmbassadorRemoteDatasource _datasource;
  const AmbassadorRepositoryImpl(this._datasource);

  Future<List<Referral>> fetchMyReferrals(String ambassadorUserId) =>
      _datasource.fetchMyReferrals(ambassadorUserId);

  Future<List<Commission>> fetchMyCommissions(String ambassadorUserId) =>
      _datasource.fetchMyCommissions(ambassadorUserId);

  Future<void> requestPayout(String commissionId, num amount) =>
      _datasource.requestPayout(commissionId, amount);

  Future<String?> ensureReferralCode() => _datasource.ensureReferralCode();
}
