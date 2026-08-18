import '../../domain/entities/commission.dart';

class CommissionModel extends Commission {
  const CommissionModel({
    required super.id,
    required super.ambassadorUserId,
    required super.amount,
    required super.status,
    super.periodStart,
    super.periodEnd,
    super.paidAt,
  });

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id:               json['id'] as String,
      ambassadorUserId: json['ambassador_user_id'] as String,
      amount:           (json['amount'] as num?) ?? 0,
      status:           _parseStatus(json['status'] as String?),
      periodStart: json['period_start'] != null
          ? DateTime.tryParse(json['period_start'] as String)
          : null,
      periodEnd: json['period_end'] != null
          ? DateTime.tryParse(json['period_end'] as String)
          : null,
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
    );
  }

  static CommissionStatus _parseStatus(String? s) => switch (s) {
    'pending' => CommissionStatus.pending,
    'payable' => CommissionStatus.payable,
    'paid'    => CommissionStatus.paid,
    _         => CommissionStatus.pending,
  };
}
