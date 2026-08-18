import 'package:flutter_test/flutter_test.dart';
import 'package:studium_mobile/features/applications/domain/entities/application.dart';
import 'package:studium_mobile/features/profile/domain/entities/academic_background.dart';
import 'package:studium_mobile/features/profile/domain/entities/student_profile.dart';
import 'package:studium_mobile/features/programs/domain/entities/program.dart';
import 'package:studium_mobile/features/programs/presentation/providers/program_providers.dart';

Program _program({
  required String id,
  bool isActive = true,
  DateTime? deadline,
  String? level,
  String? country,
  String? domain,
  String? description,
  String programName = 'Programme',
  double? minAverage,
}) =>
    Program(
      id: id,
      programName: programName,
      universityName: 'Université Test',
      isActive: isActive,
      deadline: deadline,
      level: level,
      country: country,
      domain: domain,
      description: description,
      minAverage: minAverage,
    );

Application _application({
  required String programId,
  String? level,
  String? country,
}) =>
    Application(
      id: 'a-$programId',
      studentId: 'u1',
      programId: programId,
      status: ApplicationStatus.submitted,
      level: level,
      country: country,
    );

AcademicBackground _academic({String degree = 'Licence en Informatique', double? average, int? year}) =>
    AcademicBackground(
      id: 'ac1',
      userId: 'u1',
      degree: degree,
      university: 'Univ',
      average: average,
      year: year,
    );

List<Program> _recommend({
  required List<Program> programs,
  StudentProfile? profile,
  List<AcademicBackground> academics = const [],
  List<Application> applications = const [],
  Set<String> favoriteIds = const {},
}) =>
    computeRecommendations(
      allPrograms: programs,
      profile: profile,
      academics: academics,
      applications: applications,
      favoriteIds: favoriteIds,
    );

void main() {
  group('exclusion filters', () {
    test('returns empty list when there are no programs', () {
      expect(_recommend(programs: []), isEmpty);
    });

    test('excludes inactive programs', () {
      final programs = [_program(id: 'p1', isActive: false)];
      expect(_recommend(programs: programs), isEmpty);
    });

    test('excludes expired programs', () {
      final programs = [_program(id: 'p1', deadline: DateTime.now().subtract(const Duration(days: 5)))];
      expect(_recommend(programs: programs), isEmpty);
    });

    test('excludes programs already applied to', () {
      final programs = [_program(id: 'p1')];
      final applications = [_application(programId: 'p1')];
      expect(_recommend(programs: programs, applications: applications), isEmpty);
    });

    test('excludes already-favorited programs', () {
      final programs = [_program(id: 'p1')];
      expect(_recommend(programs: programs, favoriteIds: {'p1'}), isEmpty);
    });

    test('excludes programs the student is confirmed ineligible for', () {
      final programs = [_program(id: 'p1', minAverage: 15)];
      final academics = [_academic(average: 10)];
      expect(_recommend(programs: programs, academics: academics), isEmpty);
    });

    test('keeps programs with unknown eligibility (no minAverage) via padding', () {
      final programs = [_program(id: 'p1')];
      final result = _recommend(programs: programs);
      expect(result.map((p) => p.id), ['p1']);
    });
  });

  group('scoring weights', () {
    test('ranks a program matching a past application level higher', () {
      final programs = [
        _program(id: 'bachelor', level: 'bachelor'),
        _program(id: 'master', level: 'master'),
      ];
      final applications = [_application(programId: 'other', level: 'master')];

      final result = _recommend(programs: programs, applications: applications);

      expect(result.first.id, 'master');
    });

    test('ranks a program matching a favorited program level higher', () {
      final programs = [
        _program(id: 'bachelor', level: 'bachelor'),
        _program(id: 'phd', level: 'phd'),
        _program(id: 'favorited', level: 'phd'),
      ];

      final result = _recommend(programs: programs, favoriteIds: {'favorited'});

      expect(result.first.id, 'phd');
    });

    test('infers targeted level from the latest academic degree (licence -> master)', () {
      final programs = [
        _program(id: 'bachelor', level: 'bachelor'),
        _program(id: 'master', level: 'master'),
      ];
      final academics = [_academic(degree: 'Licence en Informatique')];

      final result = _recommend(programs: programs, academics: academics);

      expect(result.first.id, 'master');
    });

    test('infers targeted level from the latest academic degree (master -> phd)', () {
      final programs = [
        _program(id: 'master', level: 'master'),
        _program(id: 'phd', level: 'phd'),
      ];
      final academics = [_academic(degree: 'Master en Informatique')];

      final result = _recommend(programs: programs, academics: academics);

      expect(result.first.id, 'phd');
    });

    test('ranks a program matching a past application country higher', () {
      final programs = [
        _program(id: 'fr', country: 'France'),
        _program(id: 'ca', country: 'Canada'),
      ];
      final applications = [_application(programId: 'other', country: 'Canada')];

      final result = _recommend(programs: programs, applications: applications);

      expect(result.first.id, 'ca');
    });

    test('ranks a program matching the profile residence country higher', () {
      final programs = [
        _program(id: 'fr', country: 'France'),
        _program(id: 'ca', country: 'Canada'),
      ];
      const profile = StudentProfile(id: 'u1', countryResidence: 'Canada');

      final result = _recommend(programs: programs, profile: profile);

      expect(result.first.id, 'ca');
    });

    test('ranks a program matching a favorited program domain higher', () {
      final programs = [
        _program(id: 'other', domain: 'Droit'),
        _program(id: 'ai', domain: 'Intelligence Artificielle'),
        _program(id: 'favorited', domain: 'Intelligence Artificielle'),
      ];

      final result = _recommend(programs: programs, favoriteIds: {'favorited'});

      expect(result.first.id, 'ai');
    });

    test('ranks a program whose domain matches the student goals text higher', () {
      final programs = [
        _program(id: 'unrelated', domain: 'Droit international'),
        _program(id: 'match', domain: 'Intelligence Artificielle'),
      ];
      const profile = StudentProfile(id: 'u1', academicGoals: "intelligence artificielle appliquée");

      final result = _recommend(programs: programs, profile: profile);

      expect(result.first.id, 'match');
    });

    test('confirmed eligibility ranks a program higher than unknown eligibility', () {
      final programs = [
        _program(id: 'unknown'),
        _program(id: 'eligible', minAverage: 10),
      ];
      final academics = [_academic(average: 15)];

      final result = _recommend(programs: programs, academics: academics);

      expect(result.first.id, 'eligible');
    });
  });

  group('sorting and padding', () {
    test('prioritizes the soonest deadline among unscored candidates', () {
      final programs = [
        _program(id: 'far', deadline: DateTime.now().add(const Duration(days: 200))),
        _program(id: 'soon', deadline: DateTime.now().add(const Duration(days: 10))),
      ];

      final result = _recommend(programs: programs);

      expect(result.first.id, 'soon');
    });

    test('caps recommendations at 10 even with more eligible candidates', () {
      final programs = List.generate(
        15,
        (i) => _program(id: 'p$i', level: 'master'),
      );
      final applications = [_application(programId: 'other', level: 'master')];

      final result = _recommend(programs: programs, applications: applications);

      expect(result.length, 10);
    });
  });
}
