enum CommissionStatus { pending, payable, paid }

class Commission {
  final String id;
  final String ambassadorUserId;
  final num amount;
  final CommissionStatus status;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? paidAt;

  const Commission({
    required this.id,
    required this.ambassadorUserId,
    required this.amount,
    required this.status,
    this.periodStart,
    this.periodEnd,
    this.paidAt,
  });

  String get statusLabel => switch (status) {
    CommissionStatus.pending => 'En cours',
    CommissionStatus.payable => 'Payable',
    CommissionStatus.paid    => 'Payée',
  };
}
