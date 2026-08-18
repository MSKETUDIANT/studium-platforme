import 'package:flutter_test/flutter_test.dart';
import 'package:studium_mobile/features/profile/domain/entities/student_profile.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

const _empty = StudentProfile(id: 'u1');

const _fullInfo = StudentProfile(
  id: 'u1',
  firstName: 'Aly',
  lastName: 'Syla',
  nationality: 'Guinea Conakry',
);

int _score(StudentProfile profile, {int academics = 0, int experiences = 0, int documents = 0}) =>
    computeCompletenessScore(
      profile: profile,
      academicsCount: academics,
      experiencesCount: experiences,
      documentsCount: documents,
    );

void main() {
  test('empty profile with no data scores 0', () {
    expect(_score(_empty), 0);
  });

  test('complete personal info alone scores 25', () {
    expect(_score(_fullInfo), 25);
  });

  test('empty firstName string does not count as complete', () {
    final profile = _fullInfo.copyWith(firstName: '');
    expect(_score(profile), 0);
  });

  test('null lastName does not count as complete', () {
    const profile = StudentProfile(id: 'u1', firstName: 'Aly', nationality: 'Guinea Conakry');
    expect(_score(profile), 0);
  });

  test('null nationality does not count as complete', () {
    const profile = StudentProfile(id: 'u1', firstName: 'Aly', lastName: 'Syla');
    expect(_score(profile), 0);
  });

  test('academics alone scores 25', () {
    expect(_score(_empty, academics: 1), 25);
  });

  test('experiences alone scores 25', () {
    expect(_score(_empty, experiences: 2), 25);
  });

  test('documents alone scores 25', () {
    expect(_score(_empty, documents: 3), 25);
  });

  test('every bucket filled scores 100', () {
    expect(_score(_fullInfo, academics: 1, experiences: 1, documents: 1), 100);
  });

  test('counts above 1 do not add extra score (binary bucket)', () {
    expect(_score(_empty, academics: 5), 25);
  });
}
