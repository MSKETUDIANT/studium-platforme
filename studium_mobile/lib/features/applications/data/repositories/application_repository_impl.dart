import '../../domain/entities/application.dart';
import '../datasources/application_remote_datasource.dart';

class ApplicationRepositoryImpl {
  final ApplicationRemoteDatasource _datasource;
  const ApplicationRepositoryImpl(this._datasource);

  Future<List<Application>> fetchMyApplications(String studentProfileId) =>
      _datasource.fetchMyApplications(studentProfileId);

  Future<Application> createApplication({
    required String studentProfileId,
    required String programId,
    bool draft = false,
  }) =>
      _datasource.createApplication(
        studentProfileId: studentProfileId,
        programId:        programId,
        draft:            draft,
      );

  Future<Application> submitDraft(String applicationId) =>
      _datasource.submitDraft(applicationId);
}
