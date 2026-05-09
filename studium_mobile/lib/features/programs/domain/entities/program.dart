class Program {
  final String id;
  final String programName;
  final String universityName;
  final String? country;
  final String? language;
  final String? level;
  final String? duration;
  final double? cost;
  final DateTime? deadline;
  final String? description;
  final String? domain;
  final List<String>? requirements;
  final String? contactEmail;
  final bool isActive;
  final DateTime? createdAt;

  const Program({
    required this.id,
    required this.programName,
    required this.universityName,
    this.country,
    this.language,
    this.level,
    this.duration,
    this.cost,
    this.deadline,
    this.description,
    this.domain,
    this.requirements,
    this.contactEmail,
    required this.isActive,
    this.createdAt,
  });

  String get levelLabel => switch (level) {
        'bachelor' => 'Licence',
        'master'   => 'Master',
        'phd'      => 'Doctorat (PhD)',
        _          => level ?? '',
      };

  String get costLabel {
    if (cost == null) return 'Non précisé';
    if (cost == 0) return 'Gratuit';
    return '${cost!.toStringAsFixed(0)} €';
  }

  String get deadlineLabel {
    if (deadline == null) return 'Non précisée';
    return '${deadline!.day.toString().padLeft(2, '0')}/'
        '${deadline!.month.toString().padLeft(2, '0')}/'
        '${deadline!.year}';
  }
}
