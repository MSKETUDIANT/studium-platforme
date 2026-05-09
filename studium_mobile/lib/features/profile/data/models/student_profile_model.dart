import '../../domain/entities/student_profile.dart';

class StudentProfileModel extends StudentProfile {
  const StudentProfileModel({
    required super.id,
    super.email,
    super.firstName,
    super.lastName,
    super.phone,
    super.nationality,
    super.birthDate,
    super.countryResidence,
    super.address,
    super.photoUrl,
    super.motivationLetter,
    super.academicGoals,
    super.careerGoals,
    super.completenessScore,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      nationality: json['nationality'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      countryResidence: json['country_residence'] as String?,
      address: json['address'] as String?,
      photoUrl: json['photo_url'] as String?,
      motivationLetter: json['motivation_letter'] as String?,
      academicGoals: json['academic_goals'] as String?,
      careerGoals: json['career_goals'] as String?,
      completenessScore: json['completeness_score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (nationality != null) 'nationality': nationality,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().split('T').first,
      if (countryResidence != null) 'country_residence': countryResidence,
      if (address != null) 'address': address,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (motivationLetter != null) 'motivation_letter': motivationLetter,
      if (academicGoals != null) 'academic_goals': academicGoals,
      if (careerGoals != null) 'career_goals': careerGoals,
      'completeness_score': completenessScore,
    };
  }

  /// Pour UPDATE — sans id
  Map<String, dynamic> toUpdateJson() {
    final json = toJson()..remove('id');
    return json;
  }

  factory StudentProfileModel.fromEntity(StudentProfile entity) {
    return StudentProfileModel(
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      phone: entity.phone,
      nationality: entity.nationality,
      birthDate: entity.birthDate,
      countryResidence: entity.countryResidence,
      address: entity.address,
      photoUrl: entity.photoUrl,
      motivationLetter: entity.motivationLetter,
      academicGoals: entity.academicGoals,
      careerGoals: entity.careerGoals,
      completenessScore: entity.completenessScore,
    );
  }
}