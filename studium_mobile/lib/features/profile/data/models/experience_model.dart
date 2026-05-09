import '../../domain/entities/experience.dart';

class ExperienceModel extends Experience {
  const ExperienceModel({
    required super.id,
    required super.studentProfileId,
    required super.company,
    required super.position,
    super.startDate,
    super.endDate,
    super.description,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      id: json['id'] as String,
      studentProfileId: json['student_profile_id'] as String,
      company: json['company'] as String,
      position: json['position'] as String,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_profile_id': studentProfileId,
        'company': company,
        'position': position,
        if (startDate != null)
          'start_date': startDate!.toIso8601String().split('T').first,
        if (endDate != null)
          'end_date': endDate!.toIso8601String().split('T').first,
        if (description != null) 'description': description,
      };

  Map<String, dynamic> toInsertJson() => {
        'student_profile_id': studentProfileId,
        'company': company,
        'position': position,
        if (startDate != null)
          'start_date': startDate!.toIso8601String().split('T').first,
        if (endDate != null)
          'end_date': endDate!.toIso8601String().split('T').first,
        if (description != null) 'description': description,
      };

  factory ExperienceModel.fromEntity(Experience entity) => ExperienceModel(
        id: entity.id,
        studentProfileId: entity.studentProfileId,
        company: entity.company,
        position: entity.position,
        startDate: entity.startDate,
        endDate: entity.endDate,
        description: entity.description,
      );
}