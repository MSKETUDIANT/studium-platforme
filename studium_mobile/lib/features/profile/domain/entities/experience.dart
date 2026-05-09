class Experience {
  final String id;
  final String studentProfileId;
  final String company;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;

  const Experience({
    required this.id,
    required this.studentProfileId,
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.description,
  });

  bool get isCurrent => endDate == null;
}