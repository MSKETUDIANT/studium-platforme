enum ApplicationStatus {
  draft,
  submitted,
  needsFix,
  verified,
  sent,
  accepted,
  rejected,
  pendingDecision,
  archived,
}

class Application {
  final String id;
  final String studentId;
  final String programId;
  final ApplicationStatus status;
  final DateTime? submittedAt;
  final DateTime? createdAt;
  final String? motivationText;
  final String? notes;
  // Joined from programs
  final String? programName;
  final String? universityName;
  final String? country;
  final String? level;

  const Application({
    required this.id,
    required this.studentId,
    required this.programId,
    required this.status,
    this.submittedAt,
    this.createdAt,
    this.motivationText,
    this.notes,
    this.programName,
    this.universityName,
    this.country,
    this.level,
  });

  String get statusLabel => switch (status) {
    ApplicationStatus.draft           => 'Brouillon',
    ApplicationStatus.submitted       => 'Soumise',
    ApplicationStatus.needsFix        => 'Correction requise',
    ApplicationStatus.verified        => 'Vérifiée',
    ApplicationStatus.sent            => 'Envoyée',
    ApplicationStatus.accepted        => 'Acceptée',
    ApplicationStatus.rejected        => 'Refusée',
    ApplicationStatus.pendingDecision => 'En attente',
    ApplicationStatus.archived        => 'Archivée',
  };

  bool get isTerminal =>
      status == ApplicationStatus.accepted ||
      status == ApplicationStatus.rejected ||
      status == ApplicationStatus.archived;

  bool get isActive => !isTerminal;
}
