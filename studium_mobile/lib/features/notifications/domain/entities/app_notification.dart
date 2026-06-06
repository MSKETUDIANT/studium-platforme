class AppNotification {
  final String  id;
  final String  type;
  final String  title;
  final String? body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime  createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.payload,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id:        id,
    type:      type,
    title:     title,
    body:      body,
    payload:   payload,
    readAt:    readAt ?? this.readAt,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:        j['id'] as String,
    type:      j['type'] as String,
    title:     j['title'] as String,
    body:      j['body'] as String?,
    payload:   (j['payload'] as Map<String, dynamic>?) ?? {},
    readAt:    j['read_at'] != null
        ? DateTime.parse(j['read_at'] as String).toLocal()
        : null,
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );
}
