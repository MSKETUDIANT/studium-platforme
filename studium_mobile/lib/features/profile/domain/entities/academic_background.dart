class AcademicBackground {
  final String id;
  final String userId;
  final String degree;
  final String university;
  final int? year;
  final double? average;

  const AcademicBackground({
    required this.id,
    required this.userId,
    required this.degree,
    required this.university,
    this.year,
    this.average,
  });
}