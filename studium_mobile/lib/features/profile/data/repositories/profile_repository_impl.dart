import '../../domain/entities/academic_background.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _datasource;

  const ProfileRepositoryImpl(this._datasource);

  @override
  Future<StudentProfile> getProfile(String userId) =>
      _datasource.getProfile(userId);

  @override
  Future<StudentProfile> upsertProfile(StudentProfile profile) =>
      _datasource.upsertProfile(profile);

  @override
  Future<String> updatePhoto(String userId, String imagePath) =>
      _datasource.updatePhoto(userId, imagePath);

  @override
  Future<void> deletePhoto(String userId) =>
      _datasource.deletePhoto(userId);

  @override
  Future<List<AcademicBackground>> getAcademicBackgrounds(String userId) =>
      _datasource.getAcademicBackgrounds(userId);

  @override
  Future<AcademicBackground> addAcademicBackground(AcademicBackground background) =>
      _datasource.addAcademicBackground(background);

  @override
  Future<AcademicBackground> updateAcademicBackground(AcademicBackground background) =>
      _datasource.updateAcademicBackground(background);

  @override
  Future<void> deleteAcademicBackground(String id) =>
      _datasource.deleteAcademicBackground(id);

  @override
  Future<List<Experience>> getExperiences(String userId) =>
      _datasource.getExperiences(userId);

  @override
  Future<Experience> addExperience(Experience experience) =>
      _datasource.addExperience(experience);

  @override
  Future<Experience> updateExperience(Experience experience) =>
      _datasource.updateExperience(experience);

  @override
  Future<void> deleteExperience(String id) =>
      _datasource.deleteExperience(id);
}