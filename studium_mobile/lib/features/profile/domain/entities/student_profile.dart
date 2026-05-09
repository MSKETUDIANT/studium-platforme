
class StudentProfile {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? nationality;
  final DateTime? birthDate;
  final String? countryResidence;
  final String? address;
  final String? photoUrl;
  final String? motivationLetter;
  final String? academicGoals;
  final String? careerGoals;
  final int completenessScore;

  const StudentProfile({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.nationality,
    this.birthDate,
    this.countryResidence,
    this.address,
    this.photoUrl,
    this.motivationLetter,
    this.academicGoals,
    this.careerGoals,
    this.completenessScore = 0,
  });

  String get fullName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    return email ?? '';
  }

  bool get isPersonalInfoComplete =>
      firstName != null && lastName != null && phone != null && nationality != null;

  bool get isMotivationComplete =>
      motivationLetter != null && motivationLetter!.length >= 100;

  StudentProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? nationality,
    DateTime? birthDate,
    String? countryResidence,
    String? address,
    String? photoUrl,
    String? motivationLetter,
    String? academicGoals,
    String? careerGoals,
    int? completenessScore,
  }) {
    return StudentProfile(
      id:                id               ?? this.id,
      email:             email            ?? this.email,
      firstName:         firstName        ?? this.firstName,
      lastName:          lastName         ?? this.lastName,
      phone:             phone            ?? this.phone,
      nationality:       nationality      ?? this.nationality,
      birthDate:         birthDate        ?? this.birthDate,
      countryResidence:  countryResidence ?? this.countryResidence,
      address:           address          ?? this.address,
      photoUrl:          photoUrl         ?? this.photoUrl,
      motivationLetter:  motivationLetter ?? this.motivationLetter,
      academicGoals:     academicGoals    ?? this.academicGoals,
      careerGoals:       careerGoals      ?? this.careerGoals,
      completenessScore: completenessScore ?? this.completenessScore,
    );
  }
}