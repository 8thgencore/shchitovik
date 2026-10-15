import 'package:common_database/common_database.dart';
import 'package:common_logger/common_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shchitovik/src/feature/catalog_sync/injection.dart';
import 'package:shchitovik/src/feature/projects/injection.dart';
import 'package:shchitovik/src/feature/settings/injection.dart';
import 'package:shchitovik/src/model/app_config.dart';

/// Container for global dependencies.
class const DependenciesContainer({
  required final Logger logger,
  required final AppConfig config,
  required final PackageInfo packageInfo,
  required final SettingsContainer settingsContainer,
  required final AppDatabase database,
  required final ProjectsContainer projectsContainer,
  required final CatalogContainer catalogContainer,
});

/// A special version of [DependenciesContainer] that is used in tests.
///
/// In order to use [DependenciesContainer] in tests, it is needed to
/// extend this class and provide the dependencies that are needed for the test.
base class const TestDependenciesContainer() implements DependenciesContainer {
  @override
  Object noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'The test tries to access ${invocation.memberName} dependency, but '
      'it was not provided. Please provide the dependency in the test. '
      'You can do it by extending this class and providing the dependency.',
    );
  }
}
