import '../../domain/entities/application.dart';

class ApplicationModel extends Application {
  const ApplicationModel({
    required super.id,
    required super.studentId,
    required super.programId,
    required super.status,
    super.submittedAt,
    super.createdAt,
    super.motivationText,
    super.notes,
    super.programName,
    super.universityName,
    super.country,
    super.level,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    final program = json['programs'] as Map<String, dynamic>?;
    return ApplicationModel(
      id:             json['id']                  as String,
      studentId:      json['student_profile_id']  as String,
      programId:      json['program_id']          as String,
      status:         _parseStatus(json['status'] as String?),
      submittedAt:    json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      createdAt:      json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      programName:    program?['program_name']    as String?,
      universityName: program?['university_name'] as String?,
      country:        program?['country']         as String?,
      level:          program?['level']           as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'student_profile_id': studentId,
    'program_id':         programId,
    'status':             'submitted',
    'submitted_at':       DateTime.now().toIso8601String(),
  };

  static ApplicationStatus _parseStatus(String? s) => switch (s) {
    'draft'            => ApplicationStatus.draft,
    'submitted'        => ApplicationStatus.submitted,
    'needsfix'         => ApplicationStatus.needsFix,
    'verified'         => ApplicationStatus.verified,
    'sent'             => ApplicationStatus.sent,
    'accepted'         => ApplicationStatus.accepted,
    'rejected'         => ApplicationStatus.rejected,
    'pending_decision' => ApplicationStatus.pendingDecision,
    'archived'         => ApplicationStatus.archived,
    _                  => ApplicationStatus.submitted,
  };
}
