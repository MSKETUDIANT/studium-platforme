enum ReferralStatus { clicked, registered, converted }

class Referral {
  final String id;
  final String ambassadorUserId;
  final String studentUserId;
  final ReferralStatus status;
  final String? studentName;
  final DateTime? createdAt;
  final DateTime? convertedAt;

  const Referral({
    required this.id,
    required this.ambassadorUserId,
    required this.studentUserId,
    required this.status,
    this.studentName,
    this.createdAt,
    this.convertedAt,
  });

  String get statusLabel => switch (status) {
    ReferralStatus.clicked    => 'Lien cliqué',
    ReferralStatus.registered => 'Inscrit',
    ReferralStatus.converted  => 'Converti',
  };
}
