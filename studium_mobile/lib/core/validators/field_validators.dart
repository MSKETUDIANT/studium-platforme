final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

String? requiredValidator(String? value, {String message = 'Ce champ est requis'}) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

String? emailValidator(String? value) {
  final required = requiredValidator(value);
  if (required != null) return required;
  if (!_emailRegex.hasMatch(value!)) return "Format d'email invalide";
  return null;
}

String? passwordValidator(String? value, {int minLength = 8}) {
  final required = requiredValidator(value, message: 'Mot de passe requis');
  if (required != null) return required;
  if (value!.length < minLength) {
    return 'Le mot de passe doit contenir au moins $minLength caractères';
  }
  return null;
}

String? confirmPasswordValidator(String? value, String original) {
  final required = requiredValidator(value, message: 'Confirmation requise');
  if (required != null) return required;
  if (value != original) return 'Les mots de passe ne correspondent pas';
  return null;
}

/// Valide une note sur 20 (virgule ou point accepté). Si [optional] est vrai,
/// une valeur vide est acceptée (champ facultatif) plutôt que rejetée.
String? gradeValidator(String? value, {bool optional = false}) {
  if (value == null || value.trim().isEmpty) {
    return optional ? null : requiredValidator(value);
  }
  final normalized = value.trim().replaceAll(',', '.');
  final grade = double.tryParse(normalized);
  if (grade == null) return 'Valeur invalide';
  if (grade < 0 || grade > 20) return 'Entre 0 et 20';
  return null;
}

int countWords(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  return trimmed.split(RegExp(r'\s+')).length;
}

/// Valide un nombre de mots entre [min] et [max]. Si [optional] est vrai, une
/// valeur vide est acceptée (champ facultatif) plutôt que rejetée.
String? wordCountValidator(String? value, {required int min, required int max, bool optional = false}) {
  if (value == null || value.trim().isEmpty) {
    return optional ? null : requiredValidator(value);
  }
  final count = countWords(value);
  if (count < min) return 'Minimum $min mots ($count actuellement)';
  if (count > max) return 'Maximum $max mots ($count actuellement)';
  return null;
}
