class StudiumUser {
  final String id;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;

  const StudiumUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });
}