import '../entities/student_profile.dart';
import '../entities/academic_background.dart';
import '../entities/experience.dart';

// ─── Exceptions ───────────────────────────────────────────────────────────────

enum ProfileErrorType {
  notFound,
  unauthorized,
  network,
  server,
  validation,
  unknown,
}

class ProfileException implements Exception {
  final String message;
  final ProfileErrorType type;

  const ProfileException(
    this.message, {
    this.type = ProfileErrorType.unknown,
  });

  @override
  String toString() => 'ProfileException(type: $type, message: $message)';
}

// ─── Repository interface ─────────────────────────────────────────────────────

abstract interface class ProfileRepository {
  Future<StudentProfile> getProfile(String userId);
  Future<StudentProfile> upsertProfile(StudentProfile profile);
  Future<String> updatePhoto(String userId, String imagePath);
  Future<void> deletePhoto(String userId);

  Future<List<AcademicBackground>> getAcademicBackgrounds(String userId);
  Future<AcademicBackground> addAcademicBackground(AcademicBackground background);
  Future<AcademicBackground> updateAcademicBackground(AcademicBackground background);
  Future<void> deleteAcademicBackground(String id);

  Future<List<Experience>> getExperiences(String userId);
  Future<Experience> addExperience(Experience experience);
  Future<Experience> updateExperience(Experience experience);
  Future<void> deleteExperience(String id);
}