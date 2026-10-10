import 'package:common_database/common_database.dart';
import 'package:shchitovik/src/feature/projects/application/projects_service.dart';
import 'package:shchitovik/src/feature/projects/data/repositories/projects_repository_impl.dart';
import 'package:shchitovik/src/feature/report_pdf/application/report_service.dart';

/// Dependencies of the projects feature.
class ProjectsContainer {
  const ProjectsContainer._(this.projectsService, this.reportService);

  /// Creates the container on top of [database].
  factory ProjectsContainer.create({required AppDatabase database, required String appVersion}) =>
      ProjectsContainer._(
        ProjectsService(
          repository: ProjectsRepositoryImpl(database: database),
          appVersion: appVersion,
        ),
        ReportService(appVersion: appVersion),
      );

  /// Project use cases.
  final ProjectsService projectsService;

  /// PDF reports.
  final ReportService reportService;
}
