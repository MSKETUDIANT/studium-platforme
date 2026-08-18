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
  final double? minAverage;
  final String? requiredLanguageLevel;

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
    this.minAverage,
    this.requiredLanguageLevel,
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
    return '${cost!.toStringAsFixed(0)} ';
  }

  String get deadlineLabel {
    if (deadline == null) return 'Non précisée';
    return '${deadline!.day.toString().padLeft(2, '0')}/'
        '${deadline!.month.toString().padLeft(2, '0')}/'
        '${deadline!.year}';
  }

  bool get isExpired {
    if (deadline == null) return false;
    final today = DateTime.now();
    return deadline!.isBefore(DateTime(today.year, today.month, today.day));
  }

  String get minAverageLabel =>
      minAverage != null ? '${minAverage!.toStringAsFixed(minAverage! % 1 == 0 ? 0 : 2)}/20' : 'Non précisée';

  String get requiredLanguageLevelLabel => requiredLanguageLevel ?? 'Aucun prérequis';

  /// null = pas assez d'info pour se prononcer (pas de seuil, ou pas de moyenne connue).
  bool? isEligibleFor(double? studentAverage) {
    if (minAverage == null || studentAverage == null) return null;
    return studentAverage >= minAverage!;
  }
}
