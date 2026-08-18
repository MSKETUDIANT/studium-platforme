import '../../domain/entities/referral.dart';

class ReferralModel extends Referral {
  const ReferralModel({
    required super.id,
    required super.ambassadorUserId,
    required super.studentUserId,
    required super.status,
    super.studentName,
    super.createdAt,
    super.convertedAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json, {String? studentName}) {
    return ReferralModel(
      id:               json['id'] as String,
      ambassadorUserId: json['ambassador_user_id'] as String,
      studentUserId:    json['student_user_id'] as String,
      status:           _parseStatus(json['status'] as String?),
      studentName:      studentName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      convertedAt: json['converted_at'] != null
          ? DateTime.tryParse(json['converted_at'] as String)
          : null,
    );
  }

  static ReferralStatus _parseStatus(String? s) => switch (s) {
    'clicked'    => ReferralStatus.clicked,
    'registered' => ReferralStatus.registered,
    'converted'  => ReferralStatus.converted,
    _            => ReferralStatus.registered,
  };
}
