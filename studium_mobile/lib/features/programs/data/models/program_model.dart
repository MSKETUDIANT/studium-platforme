import '../../domain/entities/program.dart';

class ProgramModel extends Program {
  const ProgramModel({
    required super.id,
    required super.programName,
    required super.universityName,
    super.country,
    super.language,
    super.level,
    super.duration,
    super.cost,
    super.deadline,
    super.description,
    super.domain,
    super.requirements,
    super.contactEmail,
    required super.isActive,
    super.createdAt,
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) => ProgramModel(
        id:             json['id'] as String,
        programName:    json['program_name'] as String,
        universityName: json['university_name'] as String,
        country:        json['country'] as String?,
        language:       json['language'] as String?,
        level:          json['level'] as String?,
        duration:       json['duration'] as String?,
        cost:           (json['cost'] as num?)?.toDouble(),
        deadline:       json['deadline'] != null
            ? DateTime.tryParse(json['deadline'] as String)
            : null,
        description:    json['description'] as String?,
        domain:         json['domain'] as String?,
        requirements:   (json['requirements'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        contactEmail:   json['contact_email'] as String?,
        isActive:       json['is_active'] as bool? ?? true,
        createdAt:      json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
