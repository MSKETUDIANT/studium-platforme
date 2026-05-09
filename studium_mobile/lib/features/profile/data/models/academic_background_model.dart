import '../../domain/entities/academic_background.dart';

class AcademicBackgroundModel extends AcademicBackground {
  const AcademicBackgroundModel({
    required super.id,
    required super.userId,
    required super.degree,
    required super.university,
    super.year,
    super.average,
  });

  factory AcademicBackgroundModel.fromJson(Map<String, dynamic> json) {
    return AcademicBackgroundModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      degree: json['degree'] as String,
      university: json['university'] as String,
      year: json['year'] as int?,
      average: (json['average'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'degree': degree,
      'university': university,
      if (year != null) 'year': year,
      if (average != null) 'average': average,
    };
  }

  /// Pour INSERT (sans id, généré par Supabase)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'degree': degree,
      'university': university,
      if (year != null) 'year': year,
      if (average != null) 'average': average,
    };
  }

  factory AcademicBackgroundModel.fromEntity(AcademicBackground entity) {
    return AcademicBackgroundModel(
      id: entity.id,
      userId: entity.userId,
      degree: entity.degree,
      university: entity.university,
      year: entity.year,
      average: entity.average,
    );
  }
}