import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/academic_background.dart';
import '../../domain/entities/experience.dart';
import '../../domain/entities/student_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/academic_background_model.dart';
import '../models/experience_model.dart';
import '../models/student_profile_model.dart';

const _kProfiles    = 'student_profiles';
const _kAcademics   = 'academic_backgrounds';
const _kExperiences = 'experiences';
const _kPhotoBucket = 'profile-photos';

class ProfileRemoteDatasource {
  final SupabaseClient _client;

  const ProfileRemoteDatasource(this._client);

  // ═══════════════════════════════════════════════════════════════════════════
  // STUDENT PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<StudentProfileModel> getProfile(String userId) async {
  try {
    final data = await _client
        .from(_kProfiles)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return StudentProfileModel(
        id: userId,
        completenessScore: 0,
      );
    }
    return StudentProfileModel.fromJson(data);
  } on PostgrestException catch (e) {
    throw ProfileException(e.message, type: ProfileErrorType.server);
  } catch (e) {
    throw ProfileException(e.toString());
  }
}

  Future<StudentProfileModel> upsertProfile(StudentProfile profile) async {
    try {
      final model = StudentProfileModel.fromEntity(profile);
      final data = await _client
          .from(_kProfiles)
          .upsert(model.toJson())
          .select()
          .single();
      return StudentProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<String> updatePhoto(String userId, String imagePath) async {
    try {
      final file = File(imagePath);
      final ext = imagePath.split('.').last.toLowerCase();
      final storagePath = '$userId/photo.$ext';

      await _client.storage.from(_kPhotoBucket).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _client.storage
          .from(_kPhotoBucket)
          .getPublicUrl(storagePath);

      await _client
          .from(_kProfiles)
          .update({'photo_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } on StorageException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<void> deletePhoto(String userId) async {
    try {
      // Essaie les extensions courantes
      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          await _client.storage
              .from(_kPhotoBucket)
              .remove(['$userId/photo.$ext']);
          break;
        } catch (_) {}
      }
      await _client
          .from(_kProfiles)
          .update({'photo_url': null})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACADEMIC BACKGROUNDS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<AcademicBackgroundModel>> getAcademicBackgrounds(
      String userId) async {
    try {
      final data = await _client
          .from(_kAcademics)
          .select()
          .eq('user_id', userId)
          .order('year', ascending: false);
      return (data as List)
          .map((e) => AcademicBackgroundModel.fromJson(e))
          .toList();
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<AcademicBackgroundModel> addAcademicBackground(
      AcademicBackground background) async {
    try {
      final model = AcademicBackgroundModel.fromEntity(background);
      final data = await _client
          .from(_kAcademics)
          .insert(model.toInsertJson())
          .select()
          .single();
      return AcademicBackgroundModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<AcademicBackgroundModel> updateAcademicBackground(
      AcademicBackground background) async {
    try {
      final model = AcademicBackgroundModel.fromEntity(background);
      final payload = model.toJson()..remove('id')..remove('user_id');
      final data = await _client
          .from(_kAcademics)
          .update(payload)
          .eq('id', background.id)
          .select()
          .single();
      return AcademicBackgroundModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<void> deleteAcademicBackground(String id) async {
    try {
      await _client.from(_kAcademics).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPERIENCES
  // ═══════════════════════════════════════════════════════════════════════════

 Future<List<ExperienceModel>> getExperiences(String userId) async {
  try {
    final data = await _client
        .from(_kExperiences)
        .select()
        .eq('student_profile_id', userId)  // ← ici
        .order('start_date', ascending: false);
    return (data as List).map((e) => ExperienceModel.fromJson(e)).toList();
  } on PostgrestException catch (e) {
    throw ProfileException(e.message, type: ProfileErrorType.server);
  } catch (e) {
    throw ProfileException(e.toString());
  }
}

  Future<ExperienceModel> addExperience(Experience experience) async {
    try {
      final model = ExperienceModel.fromEntity(experience);
      final data = await _client
          .from(_kExperiences)
          .insert(model.toInsertJson())
          .select()
          .single();
      return ExperienceModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<ExperienceModel> updateExperience(Experience experience) async {
    try {
      final model = ExperienceModel.fromEntity(experience);
      final payload = model.toJson()..remove('id')..remove('student_profile_id');
      final data = await _client
          .from(_kExperiences)
          .update(payload)
          .eq('id', experience.id)
          .select()
          .single();
      return ExperienceModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  Future<void> deleteExperience(String id) async {
    try {
      await _client.from(_kExperiences).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ProfileException(e.message, type: ProfileErrorType.server);
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }
}