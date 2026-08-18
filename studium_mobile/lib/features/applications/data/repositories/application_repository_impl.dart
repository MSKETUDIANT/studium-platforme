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
    List<String> documentIds = const [],
    String? motivationLetter,
  }) =>
      _datasource.createApplication(
        studentProfileId: studentProfileId,
        programId:        programId,
        draft:            draft,
        documentIds:      documentIds,
        motivationLetter: motivationLetter,
      );

  Future<Application> submitDraft(
    String applicationId, {
    List<String> documentIds = const [],
    String? motivationLetter,
  }) =>
      _datasource.submitDraft(
        applicationId,
        documentIds: documentIds,
        motivationLetter: motivationLetter,
      );

  Future<Application> resubmit(String applicationId) =>
      _datasource.resubmit(applicationId);
}
