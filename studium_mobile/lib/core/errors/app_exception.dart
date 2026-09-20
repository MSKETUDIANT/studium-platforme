/// Exception generique a message humain, sans prefixe technique dans son
/// toString() (contrairement a Exception() de Dart, qui affiche toujours
/// "Exception: ..." — inadapte quand le message est montre a l'utilisateur).
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}
