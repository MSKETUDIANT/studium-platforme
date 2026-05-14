import '../../domain/entities/application.dart';
import '../datasources/application_remote_datasource.dart';

class ApplicationRepositoryImpl {
  final ApplicationRemoteDatasource _datasource;
  const ApplicationRepositoryImpl(this._datasource);

  Future<List<Application>> fetchMyApplications(String studentId) =>
      _datasource.fetchMyApplications(studentId);

  Future<Application> createApplication({
    required String studentId,
    required String programId,
    String? motivationText,
  }) =>
      _datasource.createApplication(
        studentId:      studentId,
        programId:      programId,
        motivationText: motivationText,
      );
}
